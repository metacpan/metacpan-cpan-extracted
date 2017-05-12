################################
package CGI::Safe;
################################
$VERSION = 1.25;

use strict;
use Carp;
use CGI;
use Exporter;
use vars qw/ @ISA /;
@ISA = qw/ CGI /;

use vars qw/ $shell $path /;

BEGIN {

    # Clean up the environment and establish some defaults
    $shell = $ENV{'SHELL'};
    $path  = $ENV{'PATH'};
    delete @ENV{qw/ IFS CDPATH ENV BASH_ENV PATH SHELL /};
    $CGI::DISABLE_UPLOADS = 1;             # Disable uploads
    $CGI::POST_MAX        = 512 * 1024;    # limit posts to 512K max
}

sub import {
    if ( grep { /:(?:standard|cgi)/ } @_ ) {
        my $set_sub   = caller(0) . '::set';
        my $shell_sub = caller(0) . '::get_shell';
        my $path_sub  = caller(0) . '::get_path';
        {
            no strict 'refs';
            *{$set_sub}   = \&set;
            *{$shell_sub} = \&get_shell;
            *{$path_sub}  = \&get_path;
        }
    }

    my $index;

    # restore untainted path and shell if the list 'admin' in import list
    my %args = map { $_ => 1 } @_[ 1 .. $#_ ];

    if ( exists $args{'admin'} ) {

    # If 'admin' is specified, we'll reset the PATH and SHELL.  These will still
    # be tainted and require untainting by the CGI program.
        $ENV{'PATH'}  = $path  if defined $path;
        $ENV{'SHELL'} = $shell if defined $shell;
        delete $args{'admin'};
        splice @_, 1, $#_, keys %args;
    }

    # TODO: Future releases will allow untainting to occur at the time that CGI
    # data is grabbed.  We include this so that people will know that future
    # versions will require 'taint' in the import list to allow their scripts to
    # run with minimal changes
    if ( exists $args{'taint'} ) {
        delete $args{'taint'};
        splice @_, 1, $#_, keys %args;
    }

    # using goto to avoid updating caller
    goto &CGI::import;
}

sub new {
    my ( $class, %args ) = @_;
    $CGI::DISABLE_UPLOADS = $args{'DISABLE_UPLOADS'}
      if exists $args{'DISABLE_UPLOADS'};
    $CGI::POST_MAX = $args{'POST_MAX'} if exists $args{'POST_MAX'};
    $ENV{'PATH'}   = $args{'PATH'}     if exists $args{'PATH'};
    $ENV{'SHELL'}  = $args{'SHELL'}    if exists $args{'SHELL'};

    return CGI::new( $class,
        ( exists $args{'source'} ? $args{'source'} : () ) );
}

sub set {
    my ( $self, %args ) = CGI::self_or_default(@_);
    if ( exists $args{'DISABLE_UPLOADS'}
        and defined $args{'DISABLE_UPLOADS'} )
    {
        $CGI::DISABLE_UPLOADS = $args{'DISABLE_UPLOADS'};
    }
    if (    exists $args{'POST_MAX'}
        and defined $args{'POST_MAX'}
        and $args{'POST_MAX'} =~ /^\d+$/ )
    {
        $CGI::POST_MAX = $args{'POST_MAX'};
    }
}

sub get_path { $path }

sub get_shell { $shell }

"Ovid";

__END__

=head1 NAME

CGI::Safe - Safe method of using CGI.pm.  This is pretty much a two-line change
for most CGI scripts.

=head1 SYNOPSIS

 use CGI::Safe qw/ taint /;
 my $q = CGI::Safe->new;

=head1 DESCRIPTION

If you've been working with CGI.pm for any length of time, you know that it
allows uploads by default and does not have a maximum post size. Since it
saves the uploads as a temp file, someone can simply upload enough data to fill
up your hard drive to initiate a DOS attack. To prevent this, we're regularly
warned to include the following two lines at the top of our CGI scripts:

 $CGI::DISABLE_UPLOADS = 1;          # Disable uploads
 $CGI::POST_MAX        = 512 * 1024; # limit posts to 512K max

As long as those are their before you instantiate a CGI object (or before you
access param and related CGI functions with the function oriented interface),
you have pretty safely plugged this problem. However, most CGI scripts don't
have these lines of code.  Some suggest changing these settings directly in
CGI.pm. I dislike this for two reasons:

=over 4

=item *

If you upgrade CGI.pm, you might forget to make the change to the new version.

=item *

You may break a lot of existing code (which may or may not be a good thing
depending upon the security implications).

=back

Hence, the L<CGI::Safe> module.  It will establish the defaults for those
variables and require virtually no code changes.  Additionally, it will delete
I<%ENV> variables listed in C<perlsec> as dangerous.  The I<$ENV{ PATH }> and
I<$ENV{ SHELL }> are explicitly set in the INIT method to ensure that they are
not tainted.  These may be overriden by passing named args to the
C<CGI::Safe>'s constructor or by setting them manually.

=head1 METHODS

=head2 new

  my $cgi = CGI::Safe->new;
  my $cgi = CGI::Safe->new( %args );

Contructor for a new L<CGI::Safe> object.  See L<USAGE DETAILS> for more
information about which arguments are accepted and how they are used.

=head2 set

  CGI::Safe->set( DISABLE_UPLOADS => 0, POST_MAX => 1_024 * 1_024 );
  my $cgi = CGI::Safe->new;

Class method which sets the value for C<DISABLE_UPLOADS> and C<POST_MAX>.
Calling this method after the constructor is effectively a no-op.

=head2 get_path

 my $path = $cgi->get_path;

Returns the original C<$ENV{'PATH'}> value.  This value is tainted.

=head2 get_shell

 my $path = $cgi->get_path;

Returns the original C<$ENV{'SHELL'}> value.  This value is tainted.

=head1 USAGE DETAILS

Some people prefer the object oriented interface for CGI.pm and others prefer
the function oriented interface.  Naturally, the C<CGI::Safe> module allows
both.

 use CGI::Safe qw/ taint /;
 my $q = CGI::Safe->new( DISABLE_UPLOADS => 0 );

Or:

 use CGI::Safe qw/ :standard taint /;
 $CGI::DISABLE_UPLOADS = 0;

=head2 Uploads and Maximum post size

As mentioned earlier, most scripts that do not need uploading should have
something like the following at the start of their code to disable uploads:

 $CGI::DISABLE_UPLOADS = 1;          # Disable uploads
 $CGI::POST_MAX        = 512 * 1024; # limit posts to 512K max

The C<CGI::Safe> sets these values in an C<BEGIN{}> block.  If necessary, the
programmer can override these values two different ways.  When using the
function oriented interface, if needing file uploads and wanting to allow up
to a 1 megabyte upload, they would set these values directly I<before> using
any of the CGI.pm CGI functions:

 use CGI::Safe qw/ :standard taint /;
 $CGI::DISABLE_UPLOADS = 0;
 $CGI::POST_MAX        = 1_024 * 1_024; # limit posts to 1 meg max

If using the OO interface, you can set these explicitly I<or> pass them as
parameters to the C<CGI::Safe> constructor:

 use CGI::Safe qw/ taint /;
 my $q = CGI::Safe->new(
     DISABLE_UPLOADS => 0,
     POST_MAX        => 1_024 * 1_024 );

=head2 CGI.pm objects from input files and other sources

You can instantiate a new CGI.pm object from an input file, properly formatted
query string passed directly to the object, or even a has with name value pairs
representing the query string.  To use this functionality with the C<CGI::Safe>
module, pass this extra information in the C<source> key:

 use CGI::Safe qw/ taint /;
 my $q = CGI::Safe->new( source = $some_file_handle );

Alternatively:

 use CGI::Safe qw/ taint /;
 my $q = CGI::Safe->new( source => 'color=red&name=Ovid' );

=head2 C<CGI::Safe::set>

As of CGI::Safe::VERSION 1.1, this is a new method which allows the client a
cleaner method of setting the I<$CGI::POST_MAX> and I<$CGI::DISABLE_UPLOADS>
variables.  As expected, you may use this with both the OO or function-oriented
interface.  When used with the OO interface, it should be treated as a class
method and called B<before> instantiation of the CGI object.

 use CGI::Safe qw/ taint /;
 CGI::Safe->set( DISABLE_UPLOADS => 0, POST_MAX => 1_024 * 1_024 );
 my $q = CGI::Safe->new;

This is equivalent to the following:

 use CGI::Safe qw/ taint /;
 my $q = CGI::Safe->new(
     DISABLE_UPLOADS => 0,
     POST_MAX        => 1_024 * 1_024 );

When using the function oriented interface, the C<set> method is imported into
the client's namespace whenever :standard or :cgi is imported.  The C<set> must
be called prior to using the cgi methods.

 use CGI::Safe qw/:standard taint /;
 set( POST_MAX => 512 * 1024 );

Since the C<set> method is imported into your namespace, you should be aware of
the possibility of namespace collisions.  If you already have a subroutine
named C<set>, you should either rename the subroutine or consider using the OO
interface to CGI::Safe.

=head2 admin

If you are running your own Web server and you find deleting the I<$ENV{PATH}>
and I<$ENV{SHELL}> variables too restrictive, you can declare yourself to be
the administrator and have those variables restored.  Simply add C<admin> to
the import list:

 use CGI::Safe we/admin taint/;

Those variables will be restored, but they will still be tainted and it is
B<your> responsibility to ensure that this is done properly.  Don't use this
feature unless you know exactly what you are doing.  Period.

=head2 C<CGI::get_shell> and C<CGI::get_path>

These two methods/functions will return the original shell and path,
respectively.  These are, of course, tainted.  If either C<:standard> or
C<:cgi> is specified in the import list, these will be exported into the
caller's namespace.  These are provided in case you need them.  Once again,
don't use 'em if you're unsure of yourself.

=head1 TODO

You've probably noticed by now that all instances of C<CGI::Safe> list I<taint>
in the import list.  This is because the next major release of this module is
intended to allow for much easier untainting of form data and cookies.
Specifying I<taint> in the import list, in that release, will tell C<CGI::Safe>
that nothing is to be untainted.  As that is the default behavior, at the
present time, I wanted you to get used to it so future releases wouldn't break
your code.

=head1 Perlmonks

Many thanks to the wonderful Monks at Perlmonks.org for holding my hand while I
learned Perl.  There are far too many to name here.  Two, however, deserve
special thanks:

Ben Tilly.  L<http://www.perlmonks.org/index.pl?node_id=26179>.  I thought I
was a good programmer until I started reading his stuff.  I've learned more
about programming from him than almost any other source.

Tye McQueen. tye@metronet.com L<http://www.perlmonks.org/index.pl?node_id=22609>.
Tye, in addition to being an I<excellent> programmer, gave me good feedback
about this module and future releases will be heavily incorporating some of his
suggestions.  Tye is also sometimes known as "Lord Throll, Konqueror of..."...
oh, wait, he told me not to say that.

=head1 COPYRIGHT

Copyright (c) 2001 Curtis "Ovid" Poe.  All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself

=head1 AUTHOR

Curtis "Ovid" Poe <poec@yahoo.com>
Address bug reports and comments to: poec@yahoo.com.  When sending bug reports,
please provide the version of CGI.pm, the version of CGI::Safe, the version
of Perl, and the version of the operating system you are using.

=head1 BUGS

2001/07/13 There are no known bugs at this time.  However, I am somewhat
concerned about the use of this module with the function oriented interface.
CGI.pm uses objects internally, even when using the function oriented interface
(which is part of the reason why the function oriented interface is not faster
than the OO version).

=head1 SEE ALSO

L<CGI>

=cut
