package Bigtop;
use strict; use warnings;

use warnings::register;
use Carp;
use File::Spec;

our $VERSION = '0.38';

sub write_file {
    my $file_name    = shift;
    my $content      = shift;
    my $no_overwrite = shift || 0;

    if ( $no_overwrite and -e $file_name ) {
        if ( warnings::enabled() ) {
            warnings::warn( "$file_name already exists, skipping it.\n" );
        }
        return;
    }

    my $FILE;

    unless ( open $FILE, '>', $file_name ) {
        croak "Couldn't write to $file_name: $!\n";
    }

    print $FILE $content;

    unless( close $FILE ) {
        croak "Trouble closing $file_name: $!\n";
    }
}

sub make_module_path {
    my $module_dir  = shift;
    my $module_name = shift;

    my @sub_dirs    = split /::/, $module_name;
    # loop through subdirs, so we can make all the intervening paths
    foreach my $subdir ( 'lib', @sub_dirs ) {
        $module_dir = File::Spec->catdir( $module_dir, $subdir );
        mkdir $module_dir; 
        # mkdir can fail for two reasons, either the dir already exists,
        # in which case we don't care.  Or, the directory could not be
        # made, then caller will notice when trying to write files to it
    }

    if ( wantarray ) {
        return $module_dir, @sub_dirs;
    }
    else {
        $module_dir;
    }
}

=begin NICE_TRY

sub setup_template {
    my $class         = shift;
    my $template_text = shift || $class->get_default_template();

    return if ( $class->template_is_setup() );

    warn "about to bind for $class";

    eval {
        package $class;
        Inline->bind(
                TT                  => $template_text,
                POST_CHOMP          => 1,
                TRIM_LEADING_SPACE  => 0,
                TRIM_TRAILING_SPACE => 0,
        );
    };
    die $@ if $@;

    $class->template_is_setup( 1 );
}

=end NICE_TRY

=cut

1;
__END__

=head1 NAME

Bigtop - A web application data language processor

=head1 SYNOPSIS

See L<Bigtop::Docs::TentTut> or L<Bigtop::Docs::Tutorial> for how to create
a Bigtop file.  L<Bigtop::Docs::TOC> is a guide to all of the
documentation modules.

The real synopsis (see L<Bigtop::ScriptHelp::Style::Kickstart>):

    bigtop --new AppName 'stock<-lot
    stock(symbol,name)
    lot(bought:date,price:int4,shares:int4)'

or go manual:

    vi your_app.bigtop (or use tentmaker see Bigtop::Docs::TentTut)
    bigtop --create your_app.bigtop all

Then run your app (if you have sqlite in your path):

    cd AppName
    ./app.server

Modify your bigtop file and try again:

    bigtop docs/your_app.bigtop all

=head1 DESCRIPTION

Bigtop is a language for describing the data of a web application.  Usually
this data will be stored in a relational database.  Once you have a
description of your data, you can generate a web application from it.
This includes all the pieces you need like: the sql statements ready for
feeding to your database command line tool, the httpd.conf you need to
Include in the httpd.conf on your system, the modules that will handle
the web requests, the models that make the database tables look like classes,
etc.

If you need to alter the data model in the future, you can change your
original description to match the new reality, then regenerate the
application without fear of losing hand written code (though you may
have to modify some of it to reflect the new reality).

=head1 FUNCTIONS

This module is really a place holder, but it does provide some developer
routines (which are not exported):

=over 4

=item write_file

    use Bigtop;
    Bigtop::write_file( $file_name, $file_content, $no_overwrite )

This attempts to write C<$file_content> to C<$file_name> and dies on failures
of open or close.  Further, if you pass a true no_overwrite flag, it
will check to see if the file exists and refuse to overwrite it.  In that
case, the user gets a warning that the file has been skipped because it
already exists.  If you don't want the user to see the warning, turn off
the Bigtop warning.  To avoid fatal errors on write failures, wrap in an
eval.  Putting these together, we come to my typcial usage:

    eval {
        no warnings qw( Bigtop );
        Bigtop::write_file( $some_output_file, $content, 'no_overwrite' );
    }
    warn $@ if $@;

=item make_module_path

(Note that make_module_path uses File::Spec, so even though Unix directory
syntax is shown below, the function should work in other places.)

    use Bigtop;
    Bigtop::make_module_path( $build_dir, $module_name );

This attempts to make all the directories from $build_dir to the home
of the module.  It assumes that lib comes immediately after $build_dir.

For example, a call like:

    Bigtop::make_module_path(
        '/home/username/App-Name', 'App::Name::Subname'
    );

Attempts to make these directories:

    /home/username/App-Name/lib
    /home/username/App-Name/lib/App
    /home/username/App-Name/lib/App/Name
    /home/username/App-Name/lib/App/Name/Subname

It doesn't report failures.  Making directories can fail because the
directories already exist (in which case you probably don't care) or
because they could not be written (in which case you'll notice soon enough,
when you try to write to them).

=back

=head2 EXPORT

None.

=head1 SEE ALSO

L<Bigtop::Docs::TOC>

If you are interested in Bigtop's inner workings, consider delving into
some of these:

=over 4

=item 

L<Bigtop::Parser>

=item 

L<Bigtop::Keywords>

=item 

L<Bigtop::Backend::Init>

=item 

L<Bigtop::Backend::Init::Std>

=item 

L<Bigtop::Backend::SQL>

=item 

L<Bigtop::Backend::SQL::Postgres>

=item 

L<Bigtop::Backend::CGI>

=item 

L<Bigtop::Backend::CGI::Gantry>

=item 

L<Bigtop::Backend::Control>

=item 

L<Bigtop::Backend::Control::Gantry>

=item 

L<Bigtop::Backend::HttpdConf>

=item 

L<Bigtop::Backend::HttpdConf::Gantry>

=item 

L<Bigtop::Backend::Model>

=item 

L<Bigtop::Backend::Model::GantryDBIxClass>

=item 

L<Bigtop::Backend::SiteLook::GantryDefault>

=back

The backends come in types.  Ideally, these types all share a set of
keywords which are requested from L<Bigtop::Keywords> in the type's module.
So L<Bigtop::Backend::SQL> is meant to request the KEYWORDS that all
Bigtop::SQL::* modules use.  They may request others, but only if they are
specific to the generated target.  For example, there might be some Postgres
specific keyword which doesn't apply to other databases.  It should be
requested in C<Bigtop::Backend::SQL::Postgres>.  Even if you need backend
specific keywords, you should put them in C<Bigtop::Keywords> so tentmaker
can display them.

=head1 JOIN US

Bigtop is discussed on the Gantry mailing list.  Please visit
http://www.usegantry.org, and click on the Mailing List tab under the
banner, for instructions.

Bigtop source is available for svn checkout.  For instructions, visit:

    http://usegantry.org

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-7, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
