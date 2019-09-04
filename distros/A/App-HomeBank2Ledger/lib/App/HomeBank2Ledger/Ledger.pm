package App::HomeBank2Ledger::Ledger;
# ABSTRACT: Ledger data representation


use warnings;
use strict;

our $VERSION = '0.006'; # VERSION


sub new {
    my $class = shift;
    my %args  = @_;
    return bless {%args}, $class;
}


sub accounts     { shift->{accounts}     || [] }
sub commodities  { shift->{commodities}  || [] }
sub payees       { shift->{payees}       || [] }
sub tags         { shift->{tags}         || [] }
sub transactions { shift->{transactions} || [] }


# TODO - These should validate incoming data.

sub add_accounts {
    my $self = shift;
    push @{$self->{accounts}}, @_;
}

sub add_commodities {
    my $self = shift;
    push @{$self->{commodities}}, @_;
}

sub add_payees {
    my $self = shift;
    push @{$self->{payees}}, @_;
}

sub add_tags {
    my $self = shift;
    push @{$self->{tags}}, @_;
}

sub add_transactions {
    my $self = shift;
    push @{$self->{transactions}}, @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::HomeBank2Ledger::Ledger - Ledger data representation

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $ledger = App::HomeBank2Ledger::Ledger->new;

    $ledger->add_payees("Ann's Antiques", "Missy Automative");

    for my $payee (@{$ledger->payees}) {
        print "Payee: $payee\n";
    }

=head1 DESCRIPTION

This class provides a unified in-memory representation of a ledger, including associated metadata.

Here is a specification for the substructures:

=head2 account

This is a fully-qualified account name. Names may contain colons for representing a hierarchy of
accounts. Examples:

=over 4

=item *

"Assets:Bank:Chase1234"

=item *

"Liabilities:Credit Card:CapitalOne"

=back

=head2 commodity

This is a hashref like this:

    {
        symbol  => '$',             # required
        iso     => 'USD',           # optional
        name    => 'US Dollar',     # optional
        format  => '$1000.00',      # optional
    }

=head2 payee

This is just a string with the name of a "payee" or memo/description/narration.

=head2 tag

This is just a string with the text of a tag.

=head2 transaction

This is a hashref like this:

    {
        date        => '2019-06-12',        # required
        payee       => 'Malcolm Reynolds',  # required
        status      => 'cleared',           # optional; can be "cleared" or "pending"
        memo        => 'Medical supplies',  # optional
        postings    => [                    # required
            {
                account     => 'Some Account',  # required
                amount      => '16.25',         # required for at least n-1 postings
                commodity   => {
                    symbol  => '$',
                    format  => '$1,000.00',
                    iso     => 'USD',
                    name    => 'US Dollar',
                    syprf   => 1,
                    dchar   => '.',
                    gchar   => ',',
                    frac    => 2,
                },
                payee       => 'Somebody',      # optional
                memo        => 'Whatever',      # optional
                status      => 'pending',       # optional; can be "cleared" or "pending"
                tags        => [qw(niska train-job)],
            },
            ...
        ],
    }

=head1 ATTRIBUTES

=head2 accounts

Get an arrayref of accounts.

=head2 commodities

Get an arrayref of commodities.

=head2 payees

Get an arrayref of payees.

=head2 tags

Get an arrayref of tags.

=head2 transactions

Get an arrayref of transactions.

=head1 METHODS

=head2 new

    $ledger = App::HomeBank2Ledger::Ledger->new(%ledger_data);

Construct a new ledger instance.

=head2 add_accounts

Add accounts.

=head2 add_commodities

Add commodities.

=head2 add_payees

Add payees.

=head2 add_tags

Add tags.

=head2 add_transactions

Add transactions.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/homebank2ledger/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Charles McGarvey.

This is free software, licensed under:

  The MIT (X11) License

=cut
