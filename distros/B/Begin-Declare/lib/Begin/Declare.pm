package Begin::Declare;
    use Devel::Declare;
    use warnings;
    use strict;

    sub croak {
        s/\s+/ /g for my ($msg, $src) = @_;
        $src =~ s/^(.{20}).*/$1'.../ or $src .= q(');
        my $i;
        1 while (caller ++$i) =~ /^(?:Begin|Devel)::Declare/;
        my (undef, $file, $line) = caller $i;
        die "Begin::Declare: $msg '$src at $file line $line.\n"
    }

    my @types = qw (my our);
    push @types, 'state' if $] >= 5.010;
    my $type_re = join '|' => @types;

    sub import {
        shift;
        for (@_) {
            /^($type_re)$/i or croak "not exported", $_;
            /^[A-Z]/        or croak "first character must be uc in", $_;
        }
        @_ or @_ = map uc, grep {/my|our/ or $^H{feature_state}} @types;
        my $caller = caller;
        Devel::Declare->setup_for (
            $caller => {map {$_  => {const => \&parser}} @_}
        );
        no strict 'refs';
        *{$caller.'::'.$_} = sub (@):lvalue {@_[0 .. $#_]} for @_
    }

    our $prefix = '';
    sub get {substr Devel::Declare::get_linestr, length $prefix}
    sub set {       Devel::Declare::set_linestr $prefix . $_[0]}

    sub parser {
        local $prefix = substr get, 0, $_[1];
        my $type = strip_type();
        my $vars = strip_vars();
        check_assign();
        set "$type $vars; use Begin::Declare::Lift $vars " . get
    }

    sub strip_space {
        my $skip = Devel::Declare::toke_skipspace length $prefix;
        set substr get, $skip;
    }

    sub strip_type {
        strip_space;
        get =~ /^($type_re)(?:\b|$)/i or croak "not /$type_re/i", get;
        $prefix .= $1 . ' ';
        lc $1
    }

    sub strip_vars {
        strip_space;
        strip_parens() or do {
            (my $line = get) =~ s/^([\$\%\@])//
                or croak "not a valid sigil", get =~ /(.)/;
            my $sigil = $1;
            set $line;
            strip_space;
            ($line = get) =~ s/^(\w+)//
                or croak "not a lexical variable name", $sigil.$line;
            set $line;
            $sigil . $1
        }
    }

    sub strip_parens {
        if (get =~ /^\(/) {
            my $length = Devel::Declare::toke_scan_str length $prefix;
            my $parens = Devel::Declare::get_lex_stuff;
                         Devel::Declare::clear_lex_stuff;
            set substr get, $length;
            $parens =~ s/\s+/ /g;
            return "($parens)"
        }
    }

    sub check_assign {
        strip_space;
        /^=[^=]/ or croak "assignment '=' expected before", $_ for get
    }

    $INC{'Begin/Declare/Lift.pm'}++;
    sub Begin::Declare::Lift::import {}

    our $VERSION = '0.06';


=head1 NAME

Begin::Declare - compile time lexical variables

=head1 VERSION

version 0.06

=head1 SYNOPSIS

don't you hate writing:

    my ($foo, @bar);
    BEGIN {
        ($foo, @bar) = ('fooval', 1 .. 10);
    }

when you should be able to write:

    MY ($foo, @bar) = ('fooval', 1 .. 10);

just C< use Begin::Declare; > and you can.

=head1 EXPORT

    use Begin::Declare;

is the same as:

    use Begin::Declare qw (MY OUR); # and STATE if "use feature 'state';"

you can also write:

    use Begin::Declare qw (My Our);

if you prefer those names.

=head1 DECLARATIONS

=head2 MY ... = ...;

=over 4

works just like the keyword C< my > except it lifts the assignment to compile
time.

    MY $x = 1;            # my $x; BEGIN {$x = 1}
    MY ($y, $z) = (2, 3); # my ($y, $z); BEGIN {($y, $z) = (2, 3)}

=back

=head2 OUR ... = ...;

=over 4

works just like the keyword C< our > except it lifts the assignment to compile
time.

    OUR ($x, @xs) = 1 .. 10;  # our ($x, @xs); BEGIN {($x, @xs) = 1 .. 10}

=back

=head2 STATE ... = ...;

=over 4

works better than the keyword C< state > (since it supports list assignment
and is a proper lvalue (at least on it's rhs)) and it lifts the assignment to
compile time.

    STATE ($x, @xs) = 1 .. 10;  # state ($x, @xs); BEGIN {($x, @xs) = 1 .. 10}

    for (1 .. 5) {
        print ++STATE $x = 'a';  # bcdef
    }

=back

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

please report any bugs or feature requests to
C<bug-begin-declare at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Begin-Declare>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 ACKNOWLEDGEMENTS

the authors of L<Devel::Declare>

=head1 LICENSE AND COPYRIGHT

copyright 2011 Eric Strom.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

1
