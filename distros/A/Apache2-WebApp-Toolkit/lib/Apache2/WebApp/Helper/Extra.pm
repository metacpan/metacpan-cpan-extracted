#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Helper::Extra - Command-line helper script
#
#  DESCRIPTION
#  What is an Extra?  It is a pre-package web application that can be added
#  to an existing WebApp Toolkit project.  Each package provides additional
#  functionality that can be modified and extended to your needs.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Helper::Extra;

use strict;
use warnings;
use base 'Apache2::WebApp::Helper';
use File::Copy::Recursive qw( dircopy );
use File::Path;
use Getopt::Long qw( :config pass_through );

our $VERSION = 0.08;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# process
#
# Based on command-line arguments, install the package.

sub process {
    my $self = shift;

    my %opts;

    GetOptions (
        \%opts,
        'config=s',
        'install=s',
        'manifest=s',
        'source=s',
        'force',
        'help',
        'verbose',
      );

    my $source = $opts{source} ||= $self->get_source_path();

    if ( $opts{help}    ||
        !$opts{config}  ||
       (!$opts{install} && !$opts{manifest}) ) {

        print "\033[33mMissing or invalid options\033[0m\n\n";

        $self->help;
    }
    elsif ( $opts{manifest} ) {
        $self->manifest("$source/extra/manifest/", $opts{manifest} );
    }
    else {
        my $config = $self->config->parse( $opts{config} );

        @opts{keys %$config} = values %$config;
    }

    my $project  = $opts{project_title};
    my $doc_root = $opts{apache_doc_root};
    my $install  = $opts{install};
    my $force    = $opts{force};
    my $verbose  = $opts{verbose};

    print "Preparing for installation...\n" if ($verbose);

    $self->error("\033[31m--project_title must be alphanumeric with no spaces\033[0m")
      unless ($project =~ /^\w+?$/);

    $self->error("\033[31m--apache_doc_root selected does not exist\033[0m")
      unless (-d $doc_root);

    $self->error("\033[31m--install must be alphanumeric with no spaces\033[0m")
      unless ($install =~ /^\w+?$/);

    $self->error("\033[31m--source directory selected does not exist\033[0m")
      unless (-d $source);

    $install =~ s/(?:^|(?<=\_))(\w)/uc($1)/eg;

    my $module = $install;
    $module =~ s/\_/\:\:/g;

    my $package = "Apache2::WebApp::Extra::$module";

    unless ( $package->can('isa') ) {
        eval "require $package";

        $self->error("\033[31m--install does not exist\033[0m") if $@;
    }

    print "Updating project '$project' with new sources\n" if ($verbose);

    my $outdir = lc($install);
    my $ht_dir = "$doc_root/htdocs/extras/$outdir";
    my $ht_src = "$source/extra/htdocs/$outdir";
    my $tt_dir = "$doc_root/templates/extras/$outdir";
    my $tt_src = "$source/extra/templates/$outdir";

    # copy the website sources
    if (-e $ht_src) {
        mkpath($ht_dir, $verbose, 0755);
        dircopy($ht_src, $ht_dir) or die $!;
    }

    # copy the templates
    if (-e $tt_src) {
        mkpath($tt_dir, $verbose, 0777);
        dircopy($tt_src, $tt_dir) or die $!;
    }

    $self->set_vars(\%opts);

    # create the classes
    open (FILE, "$source/extra/manifest/$install") or $self->error("Cannot open file: $!");

    while (<FILE>) {
        chomp;

        next unless (/\/class\/$install/i);

        my $file = $_;

        $file =~ s/^(?:.+)\/(\w+|_)\.tt$/$1/;

        my $outfile = $file;

        if ($outfile =~ /\_/) {
            $outfile =~ s/(?:^|(?<=\_))(\w)/uc($1)/eg;
            $outfile =~ s/\_/\//g;
        }
        else {
            $outfile =~ s/\b(\w)/uc($1)/eg;
        }

        my $class = "$doc_root/app/$project/$outfile\.pm";

        $self->error("\033[31m--install already exists.  Must use --force to install\033[0m")
          if (-e $class && !$force);

        $self->write_file("$source/extra/class/$file\.tt", $class);
    }

    close(FILE);

    # add class names to the project - startup.pl
    open (INFILE, "$source/extra/startup/$install") or $self->error("Cannot open file: $!");
    open (OUTFILE, ">>$doc_root/bin/startup.pl")    or $self->error("Cannot open file: $!");

    while (<INFILE>) {
        chomp;
        print OUTFILE "$project\::$_\n";
    }

    close(OUTFILE);
    close(INFILE);

    print "\033[33mPackage '$install' installation complete\033[0m\n";
    exit;
}

#----------------------------------------------------------------------------+
# manifest()
#
# Command-line argument help menu.

sub manifest {
    my ($self, $path, $file) = @_;

    $file =~ s/(?:^|(?<=\_))(\w)/uc($1)/eg;

    print "\033[33mThe package ($file) provides the following files\033[0m\n\n";

    open (FILE, "$path/$file") or $self->error("Cannot open file: $!");
    while (<FILE>) {
        chomp;
        print " + $_\n";
    }
    close(FILE);

    exit;
}

#----------------------------------------------------------------------------+
# help()
#
# Command-line argument help menu.

sub help {
    my $self = shift;

    print <<ERR_OUT;
Usage: webapp-extra [OPTION...]

WebApp::Helper::Extra - Add package sources to an existing project

 Options:

      --config (default)    Instead of passing arguments, import these values from a file

      --install             Name of the Extra to install (example: Admin)
      --manifest            View the manifest of the select package.

      --source              Specify a custom source directory (default: /usr/share/webapp-toolkit)

      --force               Ignore warnings and install the package

      --help                List available command line options (this page)
      --verbose             Print messages to STDOUT

Report bugs to <mbrooks\@cpan.org>
ERR_OUT

    exit;
}

1;

__END__

=head1 NAME

Apache2::WebApp::Helper::Extra - Command-line helper script

=head1 SYNOPSIS

  use Apache2::WebApp::Helper::Extra;

  my $obj = Apache2::WebApp::Helper::Extra->new;

  $obj->process;

=head1 DESCRIPTION

What is an Extra?  It is a pre-package web application that can be added
to an existing WebApp Toolkit project.  Each package provides additional
functionality that can be modified and extended to your needs.

=head2 COMMAND-LINE

  Usage: webapp-extra [OPTION...]

  WebApp::Helper::Extra - Add package sources to an existing project

    Options:

        --config (default)    Instead of passing arguments, import these values from a file

        --install             Name of the Extra to install (example: Admin)
        --manifest            View the manifest of the select package.

        --source              Specify a custom source directory (default: /usr/share/webapp-toolkit)

        --force               Ignore warnings and install the package

        --help                List available command line options (this page)
        --verbose             Print messages to STDOUT

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Helper>, L<File::Copy::Recursive>,
L<File::Path>, L<Getopt::Long>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
