package App::podweaver;

# ABSTRACT: Run Pod::Weaver on the files within a distribution.

use warnings;
use strict;

use Carp;
use Config::Tiny;
use CPAN::Meta;
use IO::File;
use File::Copy;
use File::HomeDir;
use File::Find::Rule;
use File::Find::Rule::Perl;
use File::Find::Rule::VCS;
use File::Slurp ();
use File::Spec;
use Log::Any qw/$log/;
use Module::Metadata;
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Weaver;
use PPI::Document;
use Try::Tiny;

our $VERSION = '1.00';

sub FAIL()              { 0; }
sub SUCCESS_UNCHANGED() { 1; }
sub SUCCESS_CHANGED()   { 2; }

sub weave_file
{
    my ( $self, %input ) = @_;
    my ( $file, $no_backup, $write_to_dot_new, $weaver );
    my ( $perl, $ppi_document, $pod_after_end, @pod_tokens, $pod_str,
         $pod_document, %weave_args, $new_pod, $end, $new_perl,
         $output_file, $backup_file, $fh, $module_info );

    unless( $file = delete $input{ filename } )
    {
        $log->errorf( 'Missing file parameter in args %s', \%input )
            if $log->is_error();
        return( FAIL );
    }
    unless( $weaver = delete $input{ weaver } )
    {
        $log->errorf( 'Missing weaver parameter in args %s', \%input )
            if $log->is_error();
        return( FAIL );
    }
    $no_backup        = delete $input{ no_backup };
    $write_to_dot_new = delete $input{ new };

    #  From here and below is mostly hacked out from
    #    Dist::Zilla::Plugin::PodWeaver

    $perl = File::Slurp::read_file( $file );

    unless( $ppi_document = PPI::Document->new( \$perl ) )
    {
        $log->errorf( "PPI error in '%s': %s", $file, PPI::Document->errstr() )
            if $log->is_error();
        return( FAIL );
    }

    #  If they have some pod after __END__ then assume it's safe to put
    #  it all there.
    $pod_after_end =
        ( $ppi_document->find( 'PPI::Statement::End' ) and
          grep { $_->find_first( 'PPI::Token::Pod' ) }
              @{$ppi_document->find( 'PPI::Statement::End' )} ) ?
        1 : 0;

    @pod_tokens =
        map { "$_" } @{ $ppi_document->find( 'PPI::Token::Pod' ) || [] };
    $ppi_document->prune( 'PPI::Token::Pod' );

    if( $ppi_document->serialize =~ /^=[a-z]/m )
    {
        #  TODO: no idea what the problem is here, but DZP::PodWeaver had it...
        $log->errorf( "Can't do podweave on '%s': " .
            "there is POD inside string literals", $file )
            if $log->is_error();
        return( FAIL );
    }

    $pod_str = join "\n", @pod_tokens;
    $pod_document = Pod::Elemental->read_string( $pod_str );

#  TODO: This _really_ doesn't like being run twice on a document with
#  TODO: regions for some reason.  Comment out for now and trust they
#  TODO: have [@CorePrep] enabled.
#    Pod::Elemental::Transformer::Pod5->new->transform_node( $pod_document );

    %weave_args = (
        %input,
        pod_document => $pod_document,
        ppi_document => $ppi_document,
        filename     => $file,
        );

    $module_info = Module::Metadata->new_from_file( $file );
    if( $module_info and defined( $module_info->version() ) )
    {
        $weave_args{ version } = $module_info->version();
    }
    elsif( defined( $input{ dist_version } ) )
    {
        $log->warningf( "Unable to parse version in '%s', " .
            "using dist_version '%s'", $file, $input{ dist_version } )
            if $log->is_warning();
        $weave_args{ version } = $input{ dist_version };
    }
    else
    {
        $log->warningf( "Unable to parse version in '%s' and " .
            "no dist_version supplied", $file )
            if $log->is_warning();
    }

    #  Try::Tiny this, it can croak.
    try
    {
        $pod_document = $weaver->weave_document( \%weave_args );

        $log->errorf( "weave_document() failed on '%s': No Pod generated",
            $file )
            if $log->is_error() and not $pod_document;
    }
    catch
    {
        $log->errorf( "weave_document() failed on '%s': %s",
            $file, $_ )
            if $log->is_error();
        $pod_document = undef;
    };
    return( FAIL ) unless $pod_document;

    $new_pod = $pod_document->as_pod_string;

    $end = do {
        my $end_elem = $ppi_document->find( 'PPI::Statement::Data' )
                    || $ppi_document->find( 'PPI::Statement::End' );
        join q{}, @{ $end_elem || [] };
        };

    $ppi_document->prune( 'PPI::Statement::End' );
    $ppi_document->prune( 'PPI::Statement::Data' );

    $new_perl = $ppi_document->serialize;

    $new_perl =~ s/\n+$//;
    $new_perl .= "\n";

    $new_pod  =~ s/\n+$//;
    $new_pod  =~ s/^\n+//;
    $new_pod  .= "\n";

    if( not $end )
    {
        $end = "__END__\n\n";
        $pod_after_end = 1;
    }

    if( $pod_after_end )
    {
        $new_perl = "$new_perl\n$end$new_pod";
    }
    else
    {
        $new_perl = "$new_perl\n$new_pod\n$end";
    }

    if( $perl eq $new_perl )
    {
        $log->infof( "Contents of '%s' unchanged", $file )
            if $log->is_info();
        return( SUCCESS_UNCHANGED );
    }

    $output_file = $write_to_dot_new ? ( $file . '.new' ) : $file;
    $backup_file = $file . '.bak';

    unless( $write_to_dot_new or $no_backup )
    {
        unlink( $backup_file );
        copy( $file, $backup_file );
    }

    $log->debugf( "Writing new '%s' for '%s'", $output_file, $file )
        if $log->is_debug();
    #  We want to preserve permissions and other stuff, so we open
    #  it for read/write.
    $fh = IO::File->new( $output_file, $write_to_dot_new ? '>' : '+<' );
    unless( $fh )
    {
        $log->errorf( "Unable to write to '%s' for '%s': %s",
            $output_file, $file, $! )
            if $log->is_error();
        return( FAIL );
    }
    $fh->truncate( 0 );
    $fh->print( $new_perl );
    $fh->close();
    return( SUCCESS_CHANGED );
}

sub get_dist_info
{
    my ( $self, %options ) = @_;
    my ( $dist_info, $dist_root, $meta_file );

    $dist_root = $options{ dist_root } || '.';    

    $dist_info = {};

    if( -r ( $meta_file = File::Spec->catfile( $dist_root, 'META.json' ) ) or
        -r ( $meta_file = File::Spec->catfile( $dist_root, 'META.yml'  ) ) )
    {
        $log->debugf( "Reading '%s'", $meta_file )
            if $log->is_debug();
        $dist_info->{ meta } = CPAN::Meta->load_file( $meta_file );
    }
    else
    {
        $log->warningf( "No META.json or META.yml file found, " .
            "is '%s' a distribution directory?", $dist_root )
            if $log->is_warning();
    }

    if( $dist_info->{ meta } )
    {
        $dist_info->{ authors } = [ $dist_info->{ meta }->authors() ];

        $dist_info->{ authors } =
            [ map { s/\@/ $options{ antispam } /; $_; }
                  @{$dist_info->{ authors }} ]
            if $options{ antispam };

        $log->debug( "Creating license object" )
            if $log->is_debug();
        my @licenses = $dist_info->{ meta }->licenses();
        if( @licenses != 1 )
        {
            $log->error( "Pod::Weaver requires one, and only one, " .
                "license at a time." )
                if $log->is_error();
            return;
        }

        my $license = $licenses[ 0 ];

        #  Cribbed from Module::Build, really should be in Software::License.
        my %licenses = (
            perl         => 'Perl_5',
            perl_5       => 'Perl_5',
            apache       => 'Apache_2_0',
            apache_1_1   => 'Apache_1_1',
            artistic     => 'Artistic_1_0',
            artistic_2   => 'Artistic_2_0',
            lgpl         => 'LGPL_2_1',
            lgpl2        => 'LGPL_2_1',
            lgpl3        => 'LGPL_3_0',
            bsd          => 'BSD',
            gpl          => 'GPL_1',
            gpl2         => 'GPL_2',
            gpl3         => 'GPL_3',
            mit          => 'MIT',
            mozilla      => 'Mozilla_1_1',
            open_source  => undef,
            unrestricted => undef,
            restrictive  => undef,
            unknown      => undef,
            );

        unless( $licenses{ $license } )
        {
            $log->errorf( "Unknown license: '%s'", $license )
                if $log->is_error();
            return;
        }

        $license = $licenses{ $license };

        my $class = "Software::License::$license";
        unless( eval "use $class; 1" )
        {
            $log->errorf( "Can't load Software::License::$license: %s", $@ )
                if $log->is_error();
            return;
        }

        $dist_info->{ license } = $class->new( {
            holder => join( ' & ', @{$dist_info->{ authors }} ),
            } );

        $log->debugf( "Using license: '%s'", $dist_info->{ license }->name() )
            if $log->is_debug();

        $dist_info->{ dist_version } = $dist_info->{ meta }->version();
    }

    return( $dist_info );
}

sub get_weaver
{
    my ( $self, %options ) = @_;
    my ( $dist_root, $config_file );

    $dist_root = $options{ dist_root } || '.';    
    if( -r ( $config_file = File::Spec->catfile( $dist_root, 'weaver.ini' ) ) )
    {
        $log->debug( "Initializing weaver from ./weaver.ini" )
            if $log->is_debug();
        return( Pod::Weaver->new_from_config( {
            root => $dist_root,
            } ) );
    }
    $log->warningf( "No '%s' found, using Pod::Weaver defaults, " .
        "this will most likely insert duplicate sections",
        $config_file )
        if $log->is_warning();
    return( Pod::Weaver->new_with_default_config() );
}

sub find_files_to_weave
{
    my ( $self, %options ) = @_;
    my ( $dist_root );

    $dist_root = $options{ dist_root } || '.';    

    return(
        File::Find::Rule->ignore_vcs
                        ->not_name( qr/~$/ )
                        ->perl_file
                        ->in(
                            grep { -d $_ }
                            map  { File::Spec->catfile( $dist_root, $_ ) }
                            qw/lib bin script/
                            )
        );
}

sub weave_distribution
{
    my ( $self, %options ) = @_;
    my ( $weaver, $dist_info );

    $dist_info = $self->get_dist_info( %options );
    $weaver    = $self->get_weaver( %options );

    foreach my $file ( $self->find_files_to_weave() )
    {
        $log->noticef( "Weaving file '%s'", $file )
            if $log->is_notice();

        $self->weave_file(
            %options,
            %{$dist_info},
            filename => $file,
            weaver   => $weaver,
            );
    }
}

sub _config_dir
{
    my ( $self ) = @_;
    my ( $leaf_dir, $config_dir );

    #  Following lifted from File::UserDir.
    #  I'd use that directly but it forces creation and population of the dir.

    # Derive from the caller based on HomeDir naming scheme
    my $scheme = $File::HomeDir::IMPLEMENTED_BY or
        die "Failed to find File::HomeDir naming scheme";
    if( $scheme->isa( 'File::HomeDir::Darwin' ) or
        $scheme->isa( 'File::HomeDir::Windows' ) )
    {
        $leaf_dir = 'App-podweaver';
    }
    elsif( $scheme->isa('File::HomeDir::Unix') )
    {
        $leaf_dir = '.app-podweaver';
    }
    else
    {
        die "Unsupported HomeDir naming scheme $scheme";
    }

    $config_dir = File::Spec->catdir(
        File::HomeDir->my_data(),
        $leaf_dir
        );

    return( $config_dir );
}

sub _config_file
{
    my ( $self ) = @_;
    my ( $config_dir, $config_file );

    return( undef ) unless $config_dir = $self->_config_dir();

    $config_file = File::Spec->catfile( $config_dir, 'podweaver.ini' );
    return( $config_file );
}

sub config
{
    my ( $self ) = @_;
    my ( $config_file, $config );

    $config_file = $self->_config_file();
    return( {} ) unless $config_file and -e $config_file;
    $config = Config::Tiny->read( $config_file ) or
        die "Error reading '$config_file': " . Config::Tiny->errstr();

    return( $config );
}

1;

__END__

=pod

=head1 NAME

App::podweaver - Run Pod::Weaver on the files within a distribution.

=head1 VERSION

version 1.00

=head1 SYNOPSIS

L<App::podweaver> provides a mechanism to run L<Pod::Weaver> over the files
within a distribution, without needing to use L<Dist::Zilla>.

Where L<Dist::Zilla> works on a copy of your source code, L<App::podweaver>
is intended to modify your source code directly, and as such it is highly
recommended that you use the L<Pod::Weaver::PluginBundle::ReplaceBoilerplate>
plugin bundle so that you over-write existing POD sections, instead of the
default L<Pod::Weaver> behaviour of repeatedly appending.

You can configure the L<Pod::Weaver> invocation by providinng a
C<weaver.ini> file in the root directory of your distribution.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=end readme

=head1 BOOTSTRAPPING WITH META.json/META.yml

Since the META.json/yml file is often generated with an abstract extracted
from the POD, and L<App::podweaver> expects a valid META file for
some of the information to insert into the POD, there's a chicken-and-egg
situation on the first invocation of either.

Running L<App::podweaver> first should produce a POD with an abstract
line populated from your C<< # ABSTRACT: >> header, but without additional
sections like version and authors.
You can then generate your META file as per usual, and then run
L<App::podweaver> again to produce the missing sections:

  $ ./Build distmeta
  Creating META.yml
  ERROR: Missing required field 'dist_abstract' for metafile
  $ podweaver -v
  No META.json or META.yml file found, are you running in a distribution directory?
  Processing lib/App/podweaver.pm
  $ ./Build distmeta
  Creating META.yml
  $ podweaver -v
  Processing lib/App/podweaver.pm

This should only be neccessary on newly created distributions as
both the META and the neccessary POD abstract should be present
subsequently.

=for readme stop

=head1 METHODS

=begin :private

=head2 B<FAIL>

Indicates the file failed to be woven.

=head2 B<SUCCESS_UNCHANGED>

Indicates the file was successfully woven but resulted in no changes.

=head2 B<SUCCESS_CHANGED>

Indicates the file was successfully woven and contained changes.

=end :private

=head2 I<$success> = B<< App::podweaver->weave_file( >> I<%options> B<)>

Runs L<Pod::Weaver> on the given file, merges the generated Pod back
into the appropriate place and writes the new file out.

C<< App::podweaver->weave_file() >> returns
C<< App::podweaver::FAIL >> on failure,
and either C<< App::podweaver::SUCCESS_UNCHANGED >> or
C<< App::podweaver::SUCCESS_CHANGED >> on success,
depending on whether changes needed to be made as a result of
the weaving.

Currently these constants are not exportable.

The following options configure C<< App::podweaver->weave_file() >>:

=over

=item B<< filename => >> I<$filename> (required)

The filename of the file to weave.

=item B<< weaver => >> I<$weaver> (required)

The L<Pod::Weaver> instance to use for the weaving.

=item B<< no_backup => >> I<0> | I<1> (default: 0)

If set to a true value, no backup will be made of the original file.

=item B<< new => >> I<0> | I<1> (default: 0)

If set to a true value, the modified file will be written to the
original filename with C<.new> appended, rather than overwriting
the original.

=item B<< dist_version => >> I<$version>

If no C<$VERSION> can be parsed from the file by
L<Module::Metadata>, the version supplied in
C<dist_version> will be used as a fallback.

=back

Any additional options are passed untouched to L<Pod::Weaver>.

=head2 I<$dist_info> = B<< App::podweaver->get_dist_info( >> I<%options> B<)>

Attempts to extract the information needed by L<Pod::Weaver>
about the distribution.

It does this by examining any C<META.json> or C<META.yml> file
it finds, and by expanding various fields found within.

Valid options are:

=over

=item B<< dist_root => >> I<$directory> (default: current working directory)

Treats I<$directory> as the root directory of the distribution,
where the C<META.json> or C<META.yml> file should be found.

If not supplied, this will default to the current working directory.

=item B<< antispam => >> I<$string>

If set, any @ sign in author emails will be replaced by a space,
the given string, and a further space, in an attempt to confuse
spammers.

For example C<< antispam => 'NOSPAM' >> will transform an email
of C<< nobody@127.0.0.1 >> into C<< nobody NOSPAM 127.0.0.1 >>.

=back

=head2 I<$weaver> = B<< App::podweaver->get_weaver( >> I<%options> B<)>

Builds a L<Pod::Weaver> instance, attemping to find a C<weaver.ini>
in the distribution root directory.

Valid options are:

=over

=item B<< dist_root => >> I<$directory> (default: current working directory)

Treats I<$directory> as the root directory of the distribution,
where the C<weaver.ini> file should be found.

If not supplied, this will default to the current working directory.

=back

=head2 I<@files> = B<< App::podweaver->find_files_to_weave( >> I<%options> B<)>

Invokes L<File::Find::Rule>, L<File::Find::Rule::VCS> and
L<File::Find::Rule::Perl> to return a list of perl files that are
candidates to run L<Pod::Weaver> on in the C<lib>, C<bin> and C<script>
dirs of the distribution directory.

Valid options are:

=over

=item B<< dist_root => >> I<$directory> (default: current working directory)

Treats I<$directory> as the root directory of the distribution.

If not supplied, this will default to the current working directory.

=back

=head2 B<< App::podweaver->weave_distribution( >> I<%options> B<)>

Rolls all the other methods together to run L<Pod::Weaver> on the
appropriate files within the distribution found in the current
working directory.

=head2 I<$config> = B<< App::podweaver->config() >>

Retrieves the L<Config::Tiny> contents of the user's config file for
the application, as found in the C<podweaver.ini> file in the usual
place for user configuration files for your OS.

(C<~/.app_podweaver/podweaver.ini> for UNIX, C<~/Local Settings/Application
Data/App-podweaver/podweaver.ini> under Windows.)

=head1 KNOWN ISSUES AND BUGS

=over

=item META.json/yml bootstrap is a mess

The whole bootstrap issue with META.json/yml is ugly.

=back

=head1 REPORTING BUGS

Please report any bugs or feature requests to C<bug-app-podweaver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-podweaver>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Pod::Weaver>, L<podweaver>.

=for readme continue

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::podweaver

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-podweaver>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-podweaver>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-podweaver>

=item * Search CPAN

L<http://search.cpan.org/dist/App-podweaver/>

=back

=head1 AUTHOR

Sam Graham <libapp-podweaver-perl BLAHBLAH illusori.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2011 by Sam Graham <libapp-podweaver-perl BLAHBLAH illusori.co.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
