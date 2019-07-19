package Data::Sah::Compiler::perl::TH::str;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::str';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "!ref($dt)";
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "$dt eq $ct");
    } elsif ($which eq 'in') {
        $c->add_runtime_smartmatch_pragma($cd);
        $c->add_ccl($cd, "$dt ~~ $ct");
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'min') {
        $c->add_ccl($cd, "$dt ge $ct");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "$dt gt $ct");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "$dt le $ct");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "$dt lt $ct");
    } elsif ($which eq 'between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "$dt ge $ct\->[0] && $dt le $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl($cd, "$dt ge ".$c->literal($cv->[0]).
                            " && $dt le ".$c->literal($cv->[1]));
        }
    } elsif ($which eq 'xbetween') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "$dt gt $ct\->[0] && $dt lt $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl($cd, "$dt gt ".$c->literal($cv->[0]).
                            " && $dt lt ".$c->literal($cv->[1]));
        }
    }
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'len') {
        $c->add_ccl($cd, "length($dt) == $ct");
    } elsif ($which eq 'min_len') {
        $c->add_ccl($cd, "length($dt) >= $ct");
    } elsif ($which eq 'max_len') {
        $c->add_ccl($cd, "length($dt) <= $ct");
    } elsif ($which eq 'len_between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl(
                $cd, "length($dt) >= $ct\->[0] && ".
                    "length($dt) >= $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl(
                $cd, "length($dt) >= $cv->[0] && ".
                    "length($dt) <= $cv->[1]");
        }
    } elsif ($which eq 'has') {
        $c->add_ccl($cd, "index($dt, $ct) >= 0");
    } elsif ($which eq 'each_index') {
        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
        $self_th->gen_each($cd, "0..length($cd->{data_term})-1", '_', '$_');
        $self_th->restore_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
    } elsif ($which eq 'each_elem') {
        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
        $self_th->gen_each($cd, "0..length($cd->{data_term})-1", '_', "substr($cd->{data_term}, \$_, 1)");
        $self_th->restore_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
    } elsif ($which eq 'check_each_index') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'check_each_elem') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'uniq') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'exists') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    }
}

sub clause_encoding {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->_die($cd, "Only 'utf8' encoding is currently supported")
        unless $cv eq 'utf8';
    # currently does nothing
}

sub clause_match {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, join(
            "",
            "ref($ct) eq 'Regexp' ? $dt =~ $ct : ",
            "do { my \$re = $ct; eval { \$re = /\$re/; 1 } && ",
            "$dt =~ \$re }",
        ));
    } else {
        # simplify code and we can check regex at compile time
        my $re = $c->_str2reliteral($cd, $cv);
        $c->add_ccl($cd, "$dt =~ qr($re)");
    }
}

sub clause_is_re {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, join(
            "",
            "do { my \$re = $dt; ",
            "(eval { \$re = qr/\$re/; 1 } ? 1:0) == ($ct ? 1:0) }",
        ));
    } else {
        # simplify code
        $c->add_ccl($cd, join(
            "",
            "do { my \$re = $dt; ",
            ($cv ? "" : "!"), "(eval { \$re = qr/\$re/; 1 })",
            "}",
        ));
    }
}

1;
# ABSTRACT: perl's type handler for type "str"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::perl::TH::str - perl's type handler for type "str"

=head1 VERSION

This document describes version 0.897 of Data::Sah::Compiler::perl::TH::str (from Perl distribution Data-Sah), released on 2019-07-19.

=for Pod::Coverage ^(clause_.+|superclause_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
