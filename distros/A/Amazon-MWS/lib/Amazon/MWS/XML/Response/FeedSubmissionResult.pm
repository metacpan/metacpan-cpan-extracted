package Amazon::MWS::XML::Response::FeedSubmissionResult;

use strict;
use warnings;
use XML::Compile::Schema;
use Data::Dumper;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use namespace::clean;

=head1 NAME

Amazon::MWS::XML::Response::FeedSubmissionResult -- response parser

=head1 SYNOPSIS

  my $res = Amazon::MWS::XML::Response::FeedSubmissionResult->new(xml => $xml);
  if ($res->is_success) { ... };

=head1 ACCESSOR

=head2 xml

The xml string

=head2 xml_reader

A sub reference with the AmazonEnvelope reader.

=head2 structure

Lazy attribute built via parsing the xml string passed at the constructor.

=head1 METHODS

=head2 is_success

=head2 errors

=head2 report_errors

A list of error messages, where each element is an hashref with this keys:

=over 4

=item code (numeric)

=item type (warning or error)

=item message (human-readable)

=back

=cut

has xml => (is => 'ro', required => '1');
has xml_reader => (is => 'ro',
                   required => 1);
has structure => (is => 'lazy');

sub _build_structure {
    my $self = shift;
    my $struct = $self->xml_reader->($self->xml);
    die "not a processing report xml" unless $struct->{MessageType} eq 'ProcessingReport';
    if (@{$struct->{Message}} > 1) {
        die $self->xml . " returned more than 1 message!";
    }
    return $struct->{Message}->[0]->{ProcessingReport};
}

has skus_errors => (is => 'lazy');
has skus_warnings => (is => 'lazy');
has orders_errors => (is => 'lazy');
has orders_warnings => (is => 'lazy');

sub _build_skus_errors {
    my $self = shift;
    return $self->_parse_results(sku => 'Error');
}

sub _build_skus_warnings {
    my $self = shift;
    return $self->_parse_results(sku => 'Warning');
}

sub _build_orders_errors {
    my $self = shift;
    return $self->_parse_results(order_id => 'Error');
}

sub _build_orders_warnings {
    my $self = shift;
    return $self->_parse_results(order_id => 'Warning');
}

sub report_errors {
    my ($self) = @_;
    my $struct = $self->structure;
    my @output;
    if ($struct->{Result}) {
        foreach my $res (@{ $struct->{Result} }) {
            if (my $type = $res->{ResultCode}) {
                if ($type eq 'Error' or $type eq 'Warning') {
                    my @error_chunks;
                    my $error_code = 0;
                    if (my $details = $res->{AdditionalInfo}) {
                        foreach my $key (keys %$details) {
                            push @error_chunks, "$key: $details->{$key}";
                        }
                    }
                    push @error_chunks, $type;
                    if ($res->{ResultMessageCode}) {
                        $error_code = $res->{ResultMessageCode};
                    }
                    if ($res->{ResultDescription}) {
                        push @error_chunks, $res->{ResultDescription};
                    }
                    push @output, {
                                   code => $error_code,
                                   type => lc($type),
                                   message => join(' ', @error_chunks),
                                  };
                }
            }
        }
    }
    return @output;
}

sub _parse_results {
    my ($self, $type, $code) = @_;
    die unless ($code eq 'Error' or $code eq 'Warning');
    my $struct = $self->structure;
    my @msgs;
    my %map = (sku => 'SKU',
               order_id => 'AmazonOrderID');

    my $key = $map{$type} or die "Bad type $type";
    if ($struct->{Result}) {
        foreach my $res (@{ $struct->{Result} }) {
            if ($res->{ResultCode} and $res->{ResultCode} eq $code) {
                if (my $value = $res->{AdditionalInfo}->{$key}) {
                    push @msgs, {
                                   $type => $value,
                                   # this is a bit misnamed, but not too much
                                   error => $res->{ResultDescription} || '',
                                   code => $res->{ResultMessageCode} || '',
                                  };
                }
                else {
                    push @msgs, {
                                 error => $res->{ResultDescription} || '',
                                 code => $res->{ResultMessageCode} || '',
                                };
                }
            }
        }
    }
    @msgs ? return \@msgs : return;
}



sub is_success {
    my $self = shift;
    my $struct = $self->structure;
    if ($struct->{StatusCode} eq 'Complete') {
        # Compute the total - successful
        my $success = $struct->{ProcessingSummary}->{MessagesSuccessful};
        my $error   = $struct->{ProcessingSummary}->{MessagesWithError};
        # we ignore the warnings here.
        # my $warning = $struct->{ProcessingSummary}->{MessagesWithWarning};
        my $total   = $struct->{ProcessingSummary}->{MessagesProcessed};
        if (!$error and $total == $success) {
            return 1;
        }
    }
    return;
}

sub warnings {
    my $self = shift;
    return $self->_format_msgs($self->skus_warnings);
}

sub errors {
    my $self = shift;
    return $self->_format_msgs($self->skus_errors);
}

sub _format_msgs {
    my ($self, $list) = @_;
    if ($list && @$list) {
        my @errors;
        foreach my $err (@$list) {
            if ($err->{sku}) {
                push @errors, "SKU $err->{sku}: $err->{error} ($err->{code})";
            }
            elsif ($err->{order_id}) {
                push @errors, "Order $err->{order_id}: $err->{error} ($err->{code})";
            }
            else {
                push @errors, "$err->{error} ($err->{code})";
            }
        }
        return join("\n", @errors);
    }
    return;
}

=head2 Failures and warnings

They return a list of skus or order_id.

=over 4

=item failed_skus

=item skus_with_warnings

=item failed_orders

=item orders_with_warnings

=back

=cut

sub failed_skus {
    my ($self) = @_;
    return $self->_list_faulty(sku => $self->skus_errors);
}

sub skus_with_warnings {
    my ($self) = @_;
    return $self->_list_faulty(sku => $self->skus_warnings);
}

sub failed_orders {
    my ($self) = @_;
    return $self->_list_faulty(order_id => $self->orders_errors);
}

sub orders_with_warnings {
    my ($self) = @_;
    return $self->_list_faulty(order_id => $self->orders_warnings);
}


sub _list_faulty {
    my ($self, $what, $list) = @_;
    die unless $what;
    if ($list && @$list) {
        return map { $_->{$what} } @$list;
    }
    else {
        return;
    }
}



1;
