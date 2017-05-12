#
# Courier::Filter::Module::BlankBody class
#
# (C) 2004-2008 Julian Mehnle <julian@mehnle.net>
# $Id: BlankBody.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::BlankBody - Blank-body message filter module for the
Courier::Filter framework

=cut

package Courier::Filter::Module::BlankBody;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use Courier::Filter::Module::BlankBody;

    my $module = Courier::Filter::Module::BlankBody->new(
        response    => $response_text,

        logger      => $logger,
        inverse     => 0,
        trusting    => 0,
        testing     => 0,
        debugging   => 0
    );

    my $filter = Courier::Filter->new(
        ...
        modules     => [ $module ],
        ...
    );

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if its body is blank or consists only of whitespace, which is a
frequent symptom of stupid spammers.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::BlankBody>

Creates a new B<BlankBody> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<response>

A string that is to be returned literally as the match result in case of a
match.  Defaults to B<< "Message body is blank" >>.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/"new"> for their descriptions.

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($self, $message) = @_;
    
    return 'BlankBody: ' . ($self->{response} || 'Message body is blank')
        if $message->body =~ /^\s*$/;
    
    return undef;
        # otherwise.
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
