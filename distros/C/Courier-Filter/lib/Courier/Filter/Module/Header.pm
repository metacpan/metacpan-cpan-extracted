#
# Courier::Filter::Module::Header class
#
# (C) 2004-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Header.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::Header - Message header filter module for the
Courier::Filter framework

=cut

package Courier::Filter::Module::Header;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use Courier::Filter::Module::Header;

    my $module = Courier::Filter::Module::Header->new(
        fields      => \%patterns_by_field_name,
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
message if one of the message's header fields matches the configured criteria.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::Header>

Creates a new B<Header> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<fields>

I<Required>.  A reference to a hash containing the message header field names
and patterns (as key/value pairs) that messages are to be matched against.
Field names are matched case-insensitively.  Patterns may either be simple
strings (for exact, case-sensitive matches) or regular expression objects
created by the C<qr//> operator (for inexact, partial matches).

So for instance, to match any message from the "debian-devel" mailing list with
the subject containing something about 'duelling banjoes', you could set the
C<fields> option as follows:

    fields      => {
       'list-id'    => '<debian-devel.lists.debian.org>',
        subject     => qr/duell?ing\s+banjoe?s?/i
    }

=item B<response>

A string that is to be returned literally as the match result in case of a
match.  Defaults to B<< "Prohibited header value detected: <field>: <value>" >>.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/"new()"> for their descriptions.

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($self, $message) = @_;
    
    my $fields = $self->{fields};
    foreach my $field (keys(%$fields)) {
        my $pattern = $fields->{$field};
        my $matcher =
            UNIVERSAL::isa($pattern, 'Regexp') ?
                sub { defined($_[0]) and $_[0] =~ $pattern }
            :   sub { defined($_[0]) and $_[0] eq $pattern };
        
        my @values = $message->header($field);
        
        foreach my $value (@values) {
            if ($matcher->($value)) {
                my $field_human_readable = ucfirst(lc($field));
                return
                    'Header: ' . (
                        $self->{response} ||
                        "Prohibited header value detected: $field_human_readable: $value"
                    );
            }
        }
    }
    
    return undef;
}

=head1 SEE ALSO

L<Courier::Filter::Module::Envelope>, L<Courier::Filter::Module>,
L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
