package Apache2::Controller::NonResponseRequest;

=head1 NAME

Apache2::Controller::NonResponseRequest - internal base class w/ apreq for 
non-response handlers in Apache2::Controller framework

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

This is an INTERNAL base class and you don't need to use it.

 package Apache2::Controller;
 use base Apache2::Controller::NonResponseRequest;

 # no need to define handler() or new()
 
 1;

=head1 DESCRIPTION

This is like L<Apache2::Controller::NonResponseBase> except
that it creates the L<Apache2::Request> object and makes C<< $self >>
an inheriting subclass of it.  So using this as a base, there is
no need to dereference C<< $self->{r} >> to get at the request.
It is all C<< $self >> just like within L<Apache2::Controller>
controller modules.

You should not use this module for anything that you're doing.

=head1 METHODS

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    Apache2::Controller::NonResponseBase
    Apache2::Controller::Methods
    Apache2::Request
);

use Log::Log4perl qw(:easy);
use YAML::Syck;

use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::Log;
use Apache2::URI;
use Apache2::Const -compile => qw( :common :http :methods );

use Apache2::Controller::X;
use Apache2::Controller::Const qw( @RANDCHARS $NOT_GOOD_CHARS );
use Apache2::Controller::Funk qw( log_bad_request_reason );

=head2 new

C<new()> creates an object of the child class using
L<Apache2::Controller::NonResponseBase> and then assigns the
C<< Apache2::Request >> object to C<< $self->{r} >>.

=cut

sub new {
    my ($class, $r) = @_;

    # note the '::' in call to new, not '->' ... we have to trick the class
    my $self = Apache2::Controller::NonResponseBase::new($class, $r);

    $class = $self->{class};

    DEBUG("Created NonResponseBase of class '$class'");

    $self->{r} = Apache2::Request->new( $self->{r},);

    DEBUG("Replaced self->{r} with Apache2::Request object");

    return $self;
}

1;

=head1 SEE ALSO

L<Apache2::Controller::NonResponseBase>

L<Apache2::Request>

L<Apache2::RequestRec>

L<Apache2::Controller::Auth::OpenID> (uses this as base)

L<Apache2::Controller>

=head1 AUTHOR

Mark Hedges, C<< <hedges at formdata.biz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Mark Hedges, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

