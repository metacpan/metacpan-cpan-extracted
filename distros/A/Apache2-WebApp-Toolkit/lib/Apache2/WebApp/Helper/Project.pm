#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Helper::Project - Command-line helper script
#
#  DESCRIPTION
#  Creates the necessary project files and directories.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Helper::Project;

use strict;
use warnings;
use base 'Apache2::WebApp::Helper';
use File::Path;
use Getopt::Long qw( :config pass_through );

our $VERSION = 0.13;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# process()
#
# Based on command-line arguments, build the project files.

sub process {
    my $self = shift;

    my %opts;
   
    GetOptions (
        \%opts,
        'apache_doc_root=s',
        'apache_domain=s',
        'project_title=s',
        'project_author=s',
        'project_email=s',
        'project_version=s',
        'config=s',
        'source=s',
        'rewrite_uri',
        'help',
        'verbose',
      );

    if ( $opts{config} ) {
        my $config = $self->config->parse( $opts{config} );

        @opts{keys %$config} = values %$config;
    }

    if ( $opts{help}            ||
        !$opts{apache_doc_root} ||
        !$opts{project_title}   ) {

        print "\033[33mMissing or invalid options\033[0m\n\n";

        $self->help;
    }

    my $project  = $opts{project_title};
    my $doc_root = $opts{apache_doc_root};
    my $source   = $opts{source} ||= $self->get_source_path();
    my $verbose  = $opts{verbose};

    print "Building the project...\n" if ($verbose);

    $self->error("\033[31m--project_title must be alphanumeric with no spaces\033[0m")
      unless ($project =~ /^\w+?$/);

    $self->error("\033[31m--apache_doc_root directory selected doesn't exist\033[0m")
      unless (-d $doc_root);

    $self->error("\033[31m--apache_doc_root directory selected must be empty\033[0m")
      if (scalar <$doc_root/*>);

    $self->error("\033[31m--source directory selected does not exist\033[0m")
      unless (-d $source);

    $doc_root =~ s/\/+$//g;

    mkpath("$doc_root/app",                  $verbose, 0755);
    mkpath("$doc_root/bin",                  $verbose, 0755);
    mkpath("$doc_root/conf",                 $verbose, 0755);
    mkpath("$doc_root/htdocs",               $verbose, 0755);
    mkpath("$doc_root/logs",                 $verbose);
    mkpath("$doc_root/templates",            $verbose);
    mkpath("$doc_root/tmp",                  $verbose);
    mkpath("$doc_root/tmp/cache",            $verbose);
    mkpath("$doc_root/tmp/cache/templates",  $verbose);
    mkpath("$doc_root/tmp/uploads",          $verbose);

    # File::Path ignores default 0777, use chmod instead
    chmod 0777, "$doc_root/logs";
    chmod 0777, "$doc_root/tmp";
    chmod 0777, "$doc_root/tmp/cache";
    chmod 0777, "$doc_root/tmp/cache/templates";
    chmod 0777, "$doc_root/tmp/uploads";

    open (FILE1, ">$doc_root/logs/access_log"   ) or $self->error("Cannot open file: $!"); close(FILE1);
    open (FILE2, ">$doc_root/logs/error_log"    ) or $self->error("Cannot open file: $!"); close(FILE2);
    open (FILE3, ">$doc_root/htdocs/favicon.ico") or $self->error("Cannot open file: $!"); close(FILE3);

    print "created $doc_root/logs/access_log\n"    if ($verbose);
    print "created $doc_root/logs/error_log\n"     if ($verbose);
    print "created $doc_root/htdocs/favicon.ico\n" if ($verbose);

    $self->set_vars({
        %opts,
        package_name  => "$project\::Example",
        template_name => 'example',
        example_uri   => 'app/example',
      });

    $self->write_file("$source/class_pm.tt",    "$doc_root/app/$project/Example.pm");
    $self->write_file("$source/base_pm.tt",     "$doc_root/app/$project/Base.pm"   );
    $self->write_file("$source/startup_pl.tt",  "$doc_root/bin/startup.pl"         );
    $self->write_file("$source/htpasswd.tt",    "$doc_root/conf/htpasswd"          );
    $self->write_file("$source/webapp_conf.tt", "$doc_root/conf/webapp.conf"       );
    $self->write_file("$source/httpd_conf.tt",  "$doc_root/conf/httpd.conf"        );
    $self->write_file("$source/index_html.tt",  "$doc_root/htdocs/index.html"      );
    $self->write_file("$source/projrc.tt",      "$doc_root/.projrc"                );
    $self->write_file("$source/template.tt",    "$doc_root/templates/example.tt"   );
    $self->write_file("$source/error.tt",       "$doc_root/templates/error.tt"     );

    chmod 0666, "$doc_root/conf/htpasswd";

    print "\033[33mProject '$project' created successfully\033[0m\n";
    exit;
}

#----------------------------------------------------------------------------+
# help()
#
# Command-line argument help menu.

sub help {
    my $self = shift;

    print <<ERR_OUT;
Usage: webapp-project [OPTION...]

WebApp::Helper::Project - Creates the necessary project files and directories

 Options:

      --config (default)    Instead of passing arguments, import these values from a file

      --apache_doc_root     Absolute path to the project directory
      --apache_domain       Domain name for your project

      --project_title       Name of your project (example: Project)
      --project_author      Full name of the project owner
      --project_email       E-mail address of the project owner
      --project_version     Version number of your project

      --source              Specify a custom source directory (default: /usr/share/webapp-toolkit)

      --rewrite_uri         Remove the project name from the URI (requires mod_rewrite)

      --help                List available command line options (this page)
      --verbose             Print messages to STDOUT

Report bugs to <mbrooks\@cpan.org>
ERR_OUT

    exit;
}

1;

__END__

=head1 NAME

Apache2::WebApp::Helper::Project - Command-line helper script

=head1 SYNOPSIS

  use Apache2::WebApp::Helper::Project;

  my $obj = Apache2::WebApp::Helper::Project->new;

  $obj->process;

=head1 DESCRIPTION

Creates the necessary project files and directories.

=head1 COMMAND-LINE

  Usage: webapp-project [OPTION...]

  WebApp::Helper::Project - Creates the necessary project files and directories

    Options:

        --config (default)    Instead of passing arguments, import these values from a file

        --apache_doc_root     Absolute path to the project directory
        --apache_domain       Domain name for your project

        --project_title       Name of your project (example: Project)
        --project_author      Full name of the project owner
        --project_email       E-mail address of the project owner
        --project_version     Version number of your project

        --source              Specify a custom source directory (default: /usr/share/webapp-toolkit)

        --rewrite_uri         Remove the project name from the URI (requires mod_rewrite)

        --help                List available command line options (this page)
        --verbose             Print messages to STDOUT

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Helper>, L<Apache2::ServerRec>, L<File::Path>, L<Getopt::Long>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
