# TODO: several resources per client?
package CPAN::Testers::Common::Client;
use warnings;
use strict;

use Devel::Platform::Info;
use Probe::Perl;
use Config::Perl::V;
use Carp ();
use File::Spec;
use Capture::Tiny qw(capture);
use CPAN::Testers::Common::Client::PrereqCheck;
use CPAN::Testers::Common::Client::History;

use constant MAX_OUTPUT_LENGTH => 1_000_000;

our $VERSION = '0.14';


#==================================
#  CONSTRUCTOR
#==================================

sub new {
    my ($class, %params) = @_;
    my $self  = bless {}, $class;

    Carp::croak q[Please specify a distname]           unless $params{distname};
    Carp::croak q[Please specify the dist's author]    unless $params{author};
    Carp::croak q[Please specify a grade for the dist] unless $params{grade};

    $self->_init( %params );

    return $self;
}

sub _init {
    my ($self, %params) = @_;

    $self->grade( $params{grade} );
    $self->distname( $params{distname} );
    $self->author( $params{author} );

    $self->via( exists $params{via}
                ? $params{via}
                : "your friendly CPAN Testers client version $VERSION"
              );

    $self->comments( exists $params{comments}
                     ? $params{comments}
                     : $ENV{AUTOMATED_TESTING}
                     ? "this report is from an automated smoke testing program\nand was not reviewed by a human for accuracy"
                     : 'none provided'
                   );

    $self->command( $params{command} ) if exists $params{command};

    if ( $params{prereqs} ) {
        $self->{_meta}{prereqs} = $params{prereqs}
    }
    elsif ( $params{build_dir} ) {
        $self->_get_prereqs( $params{build_dir} );
    }

    foreach my $output ( qw( configure build test ) ) {
        my $key = $output . '_output';
        if (exists $params{$key}) {
            $self->{_output}{$output} = $params{$key};
        }
    }

    return;
}


#======================================
#  ACCESSORS
#======================================

sub comments {
    my ($self, $comment) = @_;
    $self->{_comment} = $comment if $comment;
    return $self->{_comment};
}

sub via {
    my ($self, $via) = @_;
    $self->{_via} = $via if $via;
    return $self->{_via};
}

sub author {
    my ($self, $author) = @_;
    $self->{_author} = $author if $author;
    return $self->{_author};
}


#FIXME? the distname in CPAN::Reporter is validated
# under a specific regex in line 368. We should
# move that logic here.
sub distname {
    my ($self, $distname) = @_;
    $self->{_distname} = $distname if $distname;

    return $self->{_distname};
}

sub grade {
    my ($self, $grade) = @_;
    $self->{_grade} = lc $grade if $grade;
    return $self->{_grade};
}

sub command {
    my ($self, $command) = @_;
    $self->{_command} = $command if $command;
    return $self->{_command} || '';
}

#====================================
#  PUBLIC METHODS
#====================================

sub is_duplicate {
    my ($self) = @_;

    my $grade     = $self->grade;
    my $dist_name = $self->distname;
    return 0 unless $grade && $dist_name;

    #FIXME: CPAN::Reporter allows for 3 phases: 'PL', 'make' or 'test'.
    # Until this is properly ported, we'll only use the 'test' phase.
    return CPAN::Testers::Common::Client::History::is_duplicate({
        phase     => 'test',
        grade     => $grade,
        dist_name => $dist_name,
    });
}

sub record_history {
    my ($self) = @_;

    my $grade     = $self->grade;
    my $dist_name = $self->distname;
    return unless $grade && $dist_name;

    #FIXME: CPAN::Reporter allows for 3 phases: 'PL', 'make' or 'test'.
    # Until this is properly ported, we'll only use the 'test' phase.
    return CPAN::Testers::Common::Client::History::record_history({
        phase     => 'test',
        grade     => $grade,
        dist_name => $dist_name,
    });
}

sub populate {
    my $self = shift;

    # some data is repeated between facts, so we keep a 'cache'
    $self->{_config}   = Config::Perl::V::myconfig();
    $self->{_platform} = Devel::Platform::Info->new->get_info();

    # LegacyReport creates the email, therefore it must
    # be set last so all other data is already in place.
    my @facts = qw(
        TestSummary TestOutput TesterComment
        Prereqs InstalledModules
        PlatformInfo PerlConfig TestEnvironment
        LegacyReport
    );

    foreach my $fact ( @facts ) {
        my $populator = '_populate_' . lc $fact;
        $self->{_data}{$fact} = $self->$populator;
    }

    return $self->metabase_data;
}

sub metabase_data { return shift->{_data} }

sub email {
    my $self = shift;
    my $metabase_data = $self->metabase_data || $self->populate;

    return $metabase_data->{LegacyReport}{textreport};
}


#===================================================
# POPULATORS -- these functions populate
# the object with data, triggered by the
# populate() method.
#===================================================

sub _populate_platforminfo {
    my $self = shift;
    return $self->{_platform};
}


sub _populate_perlconfig {
    my $self = shift;
    return @{ $self->{_config} }{qw(build config)};
}

sub _populate_testenvironment {

    return {
        environment_vars => _get_env_vars(),
        special_vars     => _get_special_vars(),
    };
}

sub _populate_prereqs {
    my $self = shift;

    # TODO: update Fact::Prereqs to use the new meta::spec for prereqs 
    # TODO: add the 'test' prereqs?
    return $self->{_meta}{prereqs}
        || {
              runtime   => { requires => {} },
              build     => { requires => {} },
              configure => { requires => {} },
           };
    #{
    #    configure_requires => $self->{_meta}{configure_requires} || {},
    #    build_requires     => $self->{_meta}{build_requires}     || {},
    #    requires           => $self->{_meta}{requires}           || {},
    #};
}

sub _populate_testercomment {
    my $self = shift;
    return $self->comments;
}

sub _populate_installedmodules {
    my $self = shift;

    my @toolchain_mods= qw(
        CPAN
        CPAN::Meta
        Cwd
        ExtUtils::CBuilder
        ExtUtils::Command
        ExtUtils::Install
        ExtUtils::MakeMaker
        ExtUtils::Manifest
        ExtUtils::ParseXS
        File::Spec
        JSON
        JSON::PP
        Module::Build
        Module::Signature
        Parse::CPAN::Meta
        Test::Harness
        Test::More
        YAML
        YAML::Syck
        version
    );

    my $results = _version_finder( map { $_ => 0 } @toolchain_mods );

    my %toolchain = map { $_ => $results->{$_}{have} } @toolchain_mods;
    my %prereqs = ();

    return { prereqs => \%prereqs, toolchain => \%toolchain };
}


sub _populate_legacyreport {
    my $self = shift;
    return {
        %{ $self->_populate_testsummary },
        textreport => $self->_create_email,
    }
}

sub _populate_testsummary {
    my $self = shift;

    return {
        grade        => $self->grade,
        osname       => $self->{_platform}{osname},
        osversion    => $self->{_platform}{osvers},
        archname     => $self->{_platform}{archname},
        perl_version => $self->{_config}{config}{version},
    }
}

sub _populate_testoutput {
    my $self = shift;
    return $self->{_output};
}


#=====================================================
#  FORMATTERS -- functions to aid email formatting
#=====================================================

sub _format_vars_report {
    my $variables = shift;

    my $report = "";
    foreach my $var ( sort keys %$variables ) {
        my $value = $variables->{$var};
        $value = '[undef]' if ! defined $value;
        $report .= "    $var = $value\n";
    }
    return $report;
}

sub _fix_unknown { defined $_[0] ? $_[0] : 'unknown' }

sub _format_toolchain_report {
    my $installed = shift;
    my $mod_width = _max_length( keys %$installed );
    my $ver_width = _max_length(
        map { _fix_unknown( $installed->{$_} ) } keys %$installed
    );

    my $format = "    \%-${mod_width}s \%-${ver_width}s\n";

    my $report = "";
    $report .= sprintf( $format, "Module", "Have" );
    $report .= sprintf( $format, "-" x $mod_width, "-" x $ver_width );

    for my $var ( sort keys %$installed ) {
        $report .= sprintf("    \%-${mod_width}s \%-${ver_width}s\n",
                            $var, _fix_unknown($installed->{$var}) );
    }

    return $report;
}

sub _format_prereq_report {
    my $prereqs = shift;
    my (%have, %prereq_met, $report);

    my @prereq_sections = qw( runtime build configure );

    # see what prereqs are satisfied in subprocess
    foreach my $section ( @prereq_sections ) {
        my $requires = $prereqs->{$section}{requires};
        next unless $requires and ref $requires eq 'HASH' and keys %$requires > 0;

        my $results = _version_finder( %$requires );

        foreach my $mod ( keys %$results ) {
            $have{$section}{$mod} = $results->{$mod}{have};
            $prereq_met{$section}{$mod} = $results->{$mod}{met};
        }
    }

    # find formatting widths
    my ($name_width, $need_width, $have_width) = (6, 4, 4);
    foreach my $section ( @prereq_sections ) {
        my $requires = $prereqs->{$section}{requires};
        next unless $requires and ref $requires eq 'HASH';

        foreach my $module ( keys %$requires ) {
            my $name_length = length $module;
            my $need_length = length $requires->{$module};
            my $have_length = length _fix_unknown( $have{$section}{$module} );
            $name_width = $name_length if $name_length > $name_width;
            $need_width = $need_length if $need_length > $need_width;
            $have_width = $have_length if $have_length > $have_width;
        }
    }

    my $format_str =
        "  \%1s \%-${name_width}s \%-${need_width}s \%-${have_width}s\n";

    # generate the report
    foreach my $section ( @prereq_sections ) {
      my $requires = $prereqs->{$section}{requires};
      next unless $requires and ref $requires eq 'HASH' and keys %$requires;

      $report .= "$section:\n\n"
              .  sprintf( $format_str, " ", qw/Module Need Have/ )
              .  sprintf( $format_str, " ",
                          "-" x $name_width,
                          "-" x $need_width,
                          "-" x $have_width
              );

      foreach my $module ( sort {lc $a cmp lc $b} keys %$requires ) {
        my $need = $requires->{$module};
        my $have = _fix_unknown( $have{$section}{$module} );
        my $bad = $prereq_met{$section}{$module} ? " " : "!";
        $report .= sprintf( $format_str, $bad, $module, $need, $have);
      }
      $report .= "\n";
    }

    return $report || "    No requirements found\n";
}


#==============================================
# AUXILIARY (PRIVATE) METHODS AND FUNCTIONS
#==============================================

sub _get_env_vars {
    # Entries bracketed with "/" are taken to be a regex; otherwise literal
    my @env_vars= qw(
        /HARNESS/
        /LC_/
        /PERL/
        /_TEST/
        CCFLAGS
        COMSPEC
        INCLUDE
        INSTALL_BASE
        LANG
        LANGUAGE
        LD_LIBRARY_PATH
        LDFLAGS
        LIB
        NON_INTERACTIVE
        NUMBER_OF_PROCESSORS
        PATH
        PREFIX
        PROCESSOR_IDENTIFIER
        SHELL
        TERM
        TEMP
        TMPDIR
    );

    my %env_found = ();
    foreach my $var ( @env_vars ) {
        if ( $var =~ m{^/(.+)/$} ) {
            my $re = $1;
            foreach my $found ( grep { /$re/ } keys %ENV ) {
                $env_found{$found} = $ENV{$found} if exists $ENV{$found};
            }
        }
        else {
            $env_found{$var} = $ENV{$var} if exists $ENV{$var};
        }
    }

    return \%env_found;
}

sub _get_special_vars {
    my %special_vars = (
        EXECUTABLE_NAME => $^X,
        UID             => $<,
        EUID            => $>,
        GID             => $(,
        EGID            => $),
    );

    if ( $^O eq 'MSWin32' && eval 'require Win32' ) { ## no critic
        $special_vars{'Win32::GetOSName'}    = Win32::GetOSName();
        $special_vars{'Win32::GetOSVersion'} = join( ', ', Win32::GetOSVersion() );
        $special_vars{'Win32::FsType'}       = Win32::FsType();
        $special_vars{'Win32::IsAdminUser'}  = Win32::IsAdminUser();
    }
    return \%special_vars;
}

sub _get_prereqs {
    my ($self, $dir) = @_;
    my $meta;

    foreach my $meta_file ( qw( META.json META.yml META.yaml ) ) {
        my $meta_path = File::Spec->catfile( $dir, $meta_file );
        if (-e $meta_path) {
            $meta = eval { Parse::CPAN::Meta->load_file( $dir ) };
            last if $meta;
        }
    }

    if ($meta and $meta->{'meta-spec'}{version} < 2) {
        $self->{_meta}{prereqs} = $meta->{prereqs};
    }
    return;
}

sub _max_length {
    my ($first, @rest) = @_;
    my $max = length $first;
    for my $term ( @rest ) {
        $max = length $term if length $term > $max;
    }
    return $max;
}

#--------------------------------------------------------------------------#
# _temp_filename -- stand-in for File::Temp for backwards compatibility
#
# takes an optional prefix, adds 8 random chars and returns
# an absolute pathname
#
# NOTE -- manual unlink required
#--------------------------------------------------------------------------#

sub _temp_filename {
    my ($prefix) = @_;
    # @CHARS from File::Temp
    my @CHARS = (qw/ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                 a b c d e f g h i j k l m n o p q r s t u v w x y z
                 0 1 2 3 4 5 6 7 8 9 _
             /);

    $prefix = q{} unless defined $prefix;
    $prefix .= $CHARS[ int( rand(@CHARS) ) ] for 0 .. 7;
    return File::Spec->catfile(File::Spec->tmpdir(), $prefix);
}


#--------------------------------------------------------------------------#
# _version_finder
#
# module => version pairs
#
# This is done via an external program to show installed versions exactly
# the way they would be found when test programs are run.  This means that
# any updates to PERL5LIB will be reflected in the results.
#
# File-finding logic taken from CPAN::Module::inst_file().  Logic to
# handle newer Module::Build prereq syntax is taken from
# CPAN::Distribution::unsat_prereq()
#
#--------------------------------------------------------------------------#
my $version_finder = $INC{'CPAN/Testers/Common/Client/PrereqCheck.pm'};

sub _version_finder {
    my %prereqs = @_;

    my $perl = Probe::Perl->find_perl_interpreter();
    my @prereq_results;

    my $prereq_input = _temp_filename( 'CTCC-' );
    open my $fh, '>', $prereq_input
        or die "Could not create temporary '$prereq_input' for prereq analysis: $!";
    print {$fh} map { "$_ $prereqs{$_}\n" } keys %prereqs;
    close $fh;

    my ( $prereq_result, $error, $exit ) = capture { system( $perl, $version_finder, $prereq_input ) };
    unlink $prereq_input;

    if ( length $error ) {
      print STDERR $error;
    }
    if ( not length $prereq_result) {
      warn "Got no output from CPAN::Testers::Common::Client::PrereqCheck";
    }
    my %result;
    for my $line ( split "\n", $prereq_result ) {
        next unless length $line;
        my ($mod, $met, $have) = split " ", $line;
        unless ( defined($mod) && defined($met) && defined($have) ) {
            warn "Error parsing output from CPAN::Testers::Common::Client::PrereqCheck:\n$line";
            next;
        }
        $result{$mod}{have} = $have;
        $result{$mod}{met} = $met;
    }
    return \%result;
}


sub _create_email {
    my $self = shift;

    my %intro_para = (
    'pass' => <<'HERE',
Thank you for uploading your work to CPAN.  Congratulations!
All tests were successful.
HERE

    'fail' => <<'HERE',
Thank you for uploading your work to CPAN.  However, there was a problem
testing your distribution.

If you think this report is invalid, please consult the CPAN Testers Wiki
for suggestions on how to avoid getting FAIL reports for missing library
or binary dependencies, unsupported operating systems, and so on:

http://wiki.cpantesters.org/wiki/CPANAuthorNotes
HERE

    'unknown' => <<'HERE',
Thank you for uploading your work to CPAN.  However, attempting to
test your distribution gave an inconclusive result.

This could be because your distribution had an error during the make/build
stage, did not define tests, tests could not be found, because your tests were
interrupted before they finished, or because the results of the tests could not
be parsed.  You may wish to consult the CPAN Testers Wiki:

http://wiki.cpantesters.org/wiki/CPANAuthorNotes
HERE

    'na' => <<'HERE',
Thank you for uploading your work to CPAN.  While attempting to build or test
this distribution, the distribution signaled that support is not available
either for this operating system or this version of Perl.  Nevertheless, any
diagnostic output produced is provided below for reference.  If this is not
what you expect, you may wish to consult the CPAN Testers Wiki:

http://wiki.cpantesters.org/wiki/CPANAuthorNotes
HERE

);

    my $metabase_data = $self->metabase_data;
    my %data = (
        author             => $self->author,
        dist_name          => $self->distname,
        perl_version       => $metabase_data->{TestSummary}{perl_version},
        via                => $self->via,
        grade              => $self->grade,
        comment            => $self->comments,
        command            => $self->command,
        test_log           => $metabase_data->{TestOutput}{test} || '',
        prereq_pm          => _format_prereq_report( $metabase_data->{Prereqs} ),
        env_vars           => _format_vars_report( $metabase_data->{TestEnvironment}{environment_vars} ),
        special_vars       => _format_vars_report( $metabase_data->{TestEnvironment}{special_vars} ),
        toolchain_versions => _format_toolchain_report( $metabase_data->{InstalledModules}{toolchain} ),
    );

    if ( length $data{test_log} > MAX_OUTPUT_LENGTH ) {
        my $max_k = int(MAX_OUTPUT_LENGTH/1000) . "K";
        $data{test_log} = substr( $data{test_log}, 0, MAX_OUTPUT_LENGTH)
                        . "\n\n[Output truncated after $max_k]\n\n";
    }

    return <<"EOEMAIL";
Dear $data{author},

This is a computer-generated report for $data{dist_name}
on perl $data{perl_version}, created by $data{via}.

$intro_para{ $data{grade} }
Sections of this report:

    * Tester comments
    * Program output
    * Prerequisites
    * Environment and other context

------------------------------
TESTER COMMENTS
------------------------------

Additional comments from tester:

$data{comment}

------------------------------
PROGRAM OUTPUT
------------------------------

Output from '$data{command}':

$data{test_log}
------------------------------
PREREQUISITES
------------------------------

Prerequisite modules loaded:

$data{prereq_pm}
------------------------------
ENVIRONMENT AND OTHER CONTEXT
------------------------------

Environment variables:

$data{env_vars}
Perl special variables (and OS-specific diagnostics, for MSWin32):

$data{special_vars}
Perl module toolchain versions installed:

$data{toolchain_versions}
EOEMAIL

}

42;
__END__
=encoding utf8

=head1 NAME

CPAN::Testers::Common::Client - Common class for CPAN::Testers clients


=head1 SYNOPSIS

    use CPAN::Testers::Common::Client;

    my $client = CPAN::Testers::Common::Client->new(
          author   => 'RJBS',
          distname => 'Data-UUID-1.217',
          grade    => 'pass',
    );

    # what you should send to CPAN Testers, via Metabase
    my $metabase_data = $client->populate;
    my $email_body    = $client->email;

Although the recommended way is to construct your object passing as much
information as possible:

    my $client = CPAN::Testers::Common::Client->new(
          distname         => 'Data-UUID-1.217',
          author           => 'Ricardo Signes',
          grade            => 'pass',
          comments         => 'this is an auto-generated report. Cheers!',
          via              => 'My Awesome Client App 1.0',

          # you should provide at least 'test_output' to the author,
          # otherwise he/she won't know what went wrong!
          configure_output => '...',
          build_output     => '...',
          test_output      => '...',

          # same as in a META.yml 2.0 structure
          prereqs => {
              runtime => {
                requires => {
                  'File::Basename' => '0',
                },
                recommends => {
                  'ExtUtils::ParseXS' => '2.02',
                },
              },
              build => {
                requires => {
                  'Test::More' => '0',
                },
              },
              # etc.
          },
          # alternatively, if the dist is expanded in a local dir and has a Meta 2.0 {json,yml} file
          # you can just point us to the build_dir and we'll extract the prereqs ourselves:
          # build_dir => '/tmp/Data-UUID-1.217/'
    );

=head1 DESCRIPTION

This module provides a common client for constructing metabase facts and
the legacy email message sent to CPAN Testers in a way that is properly
parsed by the extraction and report tools. It is meant to be used by all
the CPAN clients (and standalone tools) that want/need to support the
CPAN Testers infrastructure.

If you need to parse or write to the common CPAN Testers configuration file,
please refer to the B<highly experimental>
L<CPAN::Testers::Common::Client::Config>.

=head2 Constructor

=head3 new

Calling C<new()> creates a new object. You B<must> pass a hash as argument setting at least
I<distname>, I<author> and I<grade>. See below for their meaning.

=head2 Accessors

=head3 author

B<Required>.

The evaluated distribution's author. Could be a PAUSE id or a full name.

=head3 distname

B<Required>.

The distribution name, in C<Dist-Name-version.suffix> format.

=head3 grade

B<Required>.

The grade for the distribution's test result. Can be C<'pass'>, C<'fail'>,
C<'na'> or C<'unknown'>.

=head3 comments

Any additional comments from the tester. Defaults to C<'none provided'>
(but see L</AUTOMATED_TESTING> below).

=head3 via

The sender module (CPAN::Reporter, CPANPLUS, etc). Defaults to
"Your friendly CPAN Testers client".

=head3 command

The command used to test the distribution.

=head2 Methods

=head3 populate()

Will populate the object with information for each Metabase fact, and create the CPAN Testers email body.

Returns a data structure containing all metabase facts data.

=head3 email()

Returns a string to be used as body of the email to CPAN Testers.

This method B<will> call C<populate()> if populate hasn't been called yet.

=head3 metabase_data()

Returns the already populated metabase data structure. Note that this will B<NOT> call C<populate()>
so you will get undef or cached data unless you call C<populate()> yourself.

=head3 is_duplicate

Returns true if this report was already sent by the current user in the past,
and false otherwise.

=head3 record_history

Records report into the history file (so C<is_duplicate()> returns true for
it in the future.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 AUTOMATED_TESTING

If the C<AUTOMATED_TESTING> environment variable is set to true, the default comment will be:

   this report is from an automated smoke testing program
   and was not reviewed by a human for accuracy

Otherwise, the default message is C<'none provided'>.

CPAN::Testers::Common::Client::Config also has
L<< some interesting environment variables|CPAN::Testers::Common::Client::Config/"CONFIGURATION AND ENVIRONMENT" >>.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/garu/CPAN-Testers-Common-Client>

  git clone https://github.com/garu/CPAN-Testers-Common-Client.git


=head1 DIAGNOSTICS

=over 4

=item C<< Could not create temporary '$FILE' for prereq analysis: $DESCRIPTION >>

In order to analyse a distribution's pre-requirements, we must create a temporary
file C<$FILE>. The C<$DESCRIPTION> should contain the error found.

=item C<< Error parsing output from CPAN::Testers::Common::Client::PrereqCheck: $LINE >>

While parsing the pre-requirements result, the given C<$LINE> couldn't be processed
correctly. Please report the issue, patches will be welcome.

=back


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-cpan-testers-common-client@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Breno G. de Oliveira  C<< <garu@cpan.org> >>


=head1 ACKNOWLEDGMENTS

This module was created at the L<2012 Perl QA Hackathon|http://2012.qa-hackathon.org>, so a big
THANK YOU is in order to all the companies and organisations that supported it, namely the
L<Cité des Sciences|http://www.cite-sciences.fr/>, L<Diabolocom|http://www.diabolocom.com/>,
L<Dijkmat|http://www.dijkmat.nl/>, L<DuckDuckGo|http://www.duckduckgo.com/>,
L<Dyn|http://www.dyn.com/>, L<Freeside|http://freeside.biz/>, L<Hedera|http://www.hederatech.com/>,
L<Jaguar|http://www.jaguar-network.com/>, L<ShadowCat|http://www.shadow.cat/>,
L<Splio|http://www.splio.com/>, L<TECLIB'|http://www.teclib.com/>, L<Weborama|http://weborama.com/>,
L<EPO|http://www.enlightenedperl.org/>, L<$foo Magazin|http://www.perl-magazin.de/> and
L<Mongueurs de Perl|http://www.mongueurs.net/>.

Also, this module could never be done without the help, contribution and insights of
L<David Golden|https://metacpan.org/author/DAGOLDEN>,
L<Barbie|https://metacpan.org/author/BARBIE>,
L<Andreas König|https://metacpan.org/author/ANDK>
and L<Tatsuhiko Miyagawa|https://metacpan.org/author/MIYAGAWA>.

All bugs and mistakes are my own.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012-2015, Breno G. de Oliveira C<< <garu@cpan.org> >>. All rights reserved.

Parts of the internals in this distribution were refactored from
CPAN::Reporter, Copyright (c) 2012 David Golden,
and from CPAN::Version, Copyright (c) 2012 Andreas Koenig.


This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
