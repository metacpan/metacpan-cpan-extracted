package Data::Sah::Compiler::js::TH::cistr;

our $DATE = '2016-09-14'; # DATE
our $VERSION = '0.87'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::js::TH::str';
with 'Data::Sah::Type::cistr';

sub before_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    # XXX only do this when there are clauses

    # convert number to string
    $self->set_tmp_data_term($cd, "typeof($dt)=='number' ? ''+$dt : typeof($dt)=='string' ? ($dt).toLowerCase() : $dt");
}

sub after_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $self->restore_data_term($cd);
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "$dt == ($ct).toLowerCase()");
    } elsif ($which eq 'in') {
        $c->add_ccl($cd, "($ct).map(function(x) { return x.toLowerCase() }).indexOf($dt) > -1");
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'min') {
        $c->add_ccl($cd, "$dt >= ($ct).toLowerCase()");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "$dt > ($ct).toLowerCase()");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "$dt <= ($ct).toLowerCase()");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "$dt < ($ct).toLowerCase()");
    } elsif ($which eq 'between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "$dt >= (($ct)[0]).toLowerCase() && ".
                            "$dt <= (($ct)[1]).toLowerCase()");
        } else {
            # simplify code
            $c->add_ccl($cd, "$dt >= ".$c->literal(lc $cv->[0]).
                            " && $dt <= ".$c->literal(lc $cv->[1]));
        }
    } elsif ($which eq 'xbetween') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "$dt > (($ct)[0]).toLowerCase() && ".
                            "$dt < (($ct)[1]).toLowerCase()");
        } else {
            # simplify code
            $c->add_ccl($cd, "$dt > ".$c->literal(lc $cv->[0]).
                            " && $dt < ".$c->literal(lc $cv->[1]));
        }
    }
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'has') {
        $c->add_ccl($cd, "($dt).indexOf(($ct).toLowerCase()) > -1");
    } else {
        $self_th->SUPER::superclause_has_elems($which, $cd);
    }
}

sub clause_match {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    my $re;
    if ($cd->{cl_is_expr}) {
        $re = $ct;
    } else {
        $re = $c->_str2reliteral($cd, $cv);
    }

    $c->add_ccl($cd, join(
        "",
        "(function(){ ",
        "var _sahv_match = true; ",
        "try { _sahv_match = ($dt).match(RegExp($re)) } catch(e) { if (e.name=='SyntaxError') _sahv_match = false } ",
        ($cd->{cl_is_expr} ?
             "return _sahv_match == !!($ct);" :
                 "return ".($cv ? '':'!')."!!_sahv_match;"),
        "} )()",
    ));
}

1;
# ABSTRACT: js's type handler for type "cistr"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::js::TH::cistr - js's type handler for type "cistr"

=head1 VERSION

This document describes version 0.87 of Data::Sah::Compiler::js::TH::cistr (from Perl distribution Data-Sah-JS), released on 2016-09-14.

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-JS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-JS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-JS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
