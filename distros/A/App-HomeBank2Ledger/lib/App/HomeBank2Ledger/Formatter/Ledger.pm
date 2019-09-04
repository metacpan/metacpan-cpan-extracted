package App::HomeBank2Ledger::Formatter::Ledger;
# ABSTRACT: Ledger formatter


use v5.10.1;    # defined-or
use warnings;
use strict;

use App::HomeBank2Ledger::Util qw(commify rtrim);

use parent 'App::HomeBank2Ledger::Formatter';

our $VERSION = '0.006'; # VERSION

my %STATUS_SYMBOLS = (
    cleared => '*',
    pending => '!',
);

sub _croak { require Carp; Carp::croak(@_) }

sub format {
    my $self   = shift;
    my $ledger = shift;

    my @out = (
        $self->format_header,
        $self->format_accounts($ledger),
        $self->format_commodities($ledger),
        $self->format_payees($ledger),
        $self->format_tags($ledger),
        $self->format_transactions($ledger),
    );

    return join($/, map { rtrim($_) } @out);
}


sub format_header {
    my $self = shift;

    my @out;

    if (my $name = $self->name) {
        push @out, "; Name: $name";
    }
    if (my $file = $self->file) {
        push @out, "; File: $file";
    }

    push @out, '';

    return @out;
}


sub format_accounts {
    my $self   = shift;
    my $ledger = shift;

    my @out;

    push @out, map { "account $_" } sort @{$ledger->accounts};
    push @out, '';

    return @out;
}


sub format_commodities {
    my $self   = shift;
    my $ledger = shift;

    my @out;

    for my $commodity (@{$ledger->commodities}) {
        push @out, "commodity $commodity->{symbol}";
        push @out, "    note $commodity->{name}"     if $commodity->{name};
        push @out, "    format $commodity->{format}" if $commodity->{format};
        push @out, "    alias $commodity->{iso}"     if $commodity->{iso};
    }

    push @out, '';

    return @out;
}


sub format_payees {
    my $self   = shift;
    my $ledger = shift;

    my @out;

    push @out, map { "payee $_" } sort @{$ledger->payees};
    push @out, '';

    return @out;
}


sub format_tags {
    my $self   = shift;
    my $ledger = shift;

    my @out;

    push @out, map { "tag $_" } sort @{$ledger->tags};
    push @out, '';

    return @out;
}


sub format_transactions {
    my $self   = shift;
    my $ledger = shift;

    my @out;

    for my $transaction (@{$ledger->transactions}) {
        push @out, $self->_format_transaction($transaction);
    }

    return @out;
}

sub _format_transaction {
    my $self = shift;
    my $transaction = shift;

    my $account_width = $self->account_width;

    my $date        = $transaction->{date};
    my $status      = $transaction->{status};
    my $payee       = $self->_format_string($transaction->{payee} || '');
    my $memo        = $self->_format_string($transaction->{memo}  || '');
    my @postings    = @{$transaction->{postings}};

    my @out;

    # figure out the Ledger transaction status
    my $status_symbol = $STATUS_SYMBOLS{$status || ''};
    if (!$status_symbol) {
        my %posting_statuses = map { ($_->{status} || '') => 1 } @postings;
        if (keys(%posting_statuses) == 1) {
            my ($status) = keys %posting_statuses;
            $status_symbol = $STATUS_SYMBOLS{$status || 'none'} || '';
        }
    }

    $payee =~ s/(?:  )|\t;/ ;/g;    # don't turn into a memo

    push @out, sprintf('%s%s%s%s', $date,
        $status_symbol && " ${status_symbol}",
        $payee         && " $payee",
        $memo          && "  ; $memo",
    );

    my $metadata = $transaction->{metadata} || {};
    for my $key (sort keys %$metadata) {
        my $value = $self->_format_string($metadata->{$key});
        push @out, "    ; ${key}: ${value}";
    }

    for my $posting (@postings) {
        my @line;

        my $posting_status_symbol = '';
        if (!$status_symbol) {
            $posting_status_symbol = $STATUS_SYMBOLS{$posting->{status} || ''} || '';
        }

        push @line, ($posting_status_symbol ? "  $posting_status_symbol " : '    ');
        push @line, sprintf("\%-${account_width}s", $posting->{account});
        push @line, '  ';
        if (defined $posting->{amount}) {
            push @line, $self->_format_amount($posting->{amount}, $posting->{commodity});
            if (my $price = $posting->{lot_price}) {
                my $is_fixed = $posting->{lot_fixed};
                my $fixed_symbol = $is_fixed ? '=' : '';
                push @line, " {${fixed_symbol}",
                            $self->_format_amount($price->{amount}, $price->{commodity}),
                            '}';
            }
            if (my $lot_date = $posting->{lot_date}) {
                push @line, " [$posting->{lot_date}]";
            }
            if (my $cost = $posting->{total_cost} // $posting->{cost}) {
                my $is_total = defined $posting->{total_cost};
                my $cost_symbol = $is_total ? '@@' : '@';
                push @line, ' ', $cost_symbol, ' ',
                            $self->_format_amount($cost->{amount}, $cost->{commodity});
            }
        }
        if (my $note = $posting->{note}) {
            $note = $self->_format_string($note);
            push @line, "  ; $note" if $note ne $memo;
        }

        push @out, join('', @line);

        my $metadata = $posting->{metadata} || {};
        for my $key (sort keys %$metadata) {
            my $value = $self->_format_string($metadata->{$key});
            push @out, "      ; ${key}: ${value}";
        }

        if (my $posting_payee = $posting->{payee}) {
            $posting_payee = $self->_format_string($posting_payee);
            push @out, "      ; Payee: $posting_payee" if $posting_payee ne $payee;
        }

        if (my @tags = @{$posting->{tags} || []}) {
            push @out, '      ; :'.join(':', @tags).':';
        }
    }

    push @out, '';

    return @out;
}

sub _format_string {
    my $self = shift;
    my $str  = shift;
    $str =~ s/\v//g;
    return $str;
}

sub _quote_string {
    my $self = shift;
    my $str  = shift;
    $str =~ s/"/\\"/g;
    return "\"$str\"";
}

sub _format_amount {
    my $self      = shift;
    my $amount    = shift;
    my $commodity = shift or _croak 'Must provide a valid currency';

    my $format = "\% .$commodity->{frac}f";
    my ($whole, $fraction) = split(/\./, sprintf($format, $amount));

    my $num = join($commodity->{dchar}, commify($whole, $commodity->{gchar}), $fraction);

    my $symbol = $commodity->{symbol};
    $symbol = $self->_quote_string($symbol) if $symbol =~ /[0-9\s]/;

    $num = $commodity->{syprf} ? "$symbol $num" : "$num $symbol";

    return $num;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::HomeBank2Ledger::Formatter::Ledger - Ledger formatter

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This is a formatter for L<Ledger|https://www.ledger-cli.org/>.

=head1 METHODS

=head2 format_header

    @lines = $formatter->format_header;

Get formatted header. For example,

    ; Name: My Finances
    ; File: path/to/finances.xhb

=head2 format_accounts

    @lines = $formatter->format_accounts($ledger);

Get formatted accounts. For example,

    account Assets:Bank:Credit Union:Savings
    account Assets:Bank:Credit Union:Checking
    ...

=head2 format_commodities

    @lines = $formatter->format_commodities($ledger);

Get formattted commodities. For example,

    commodity $
        note US Dollar
        format $  1,000.00
        alias USD
    ...

=head2 format_payees

    @lines = $formatter->format_payees($ledger);

Get formatted payees. For example,

    payee 180 Tacos
    ...

=head2 format_tags

    @lines = $formatter->format_tags($ledger);

Get formatted tags. For example,

    tag yapc
    ...

=head2 format_transactions

    @lines = $formatter->format_transactions($ledger);

Get formatted transactions. For example,

    2003-02-14 * Opening Balance
        Assets:Bank:Credit Union:Savings          $  458.21
        Assets:Bank:Credit Union:Checking         $  194.17
        Equity:Opening Balances

    ...

=head1 SEE ALSO

L<App::HomeBank2Ledger::Formatter>

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
