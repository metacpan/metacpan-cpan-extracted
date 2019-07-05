package Data::Sah::Compiler::perl::TH::timeofday;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;
use Scalar::Util qw(blessed looks_like_number);

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::timeofday';

sub handle_type {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $dt = $cd->{data_term};

    $cd->{coerce_to} = $cd->{nschema}[1]{"x.perl.coerce_to"} // 'str_hms';

    my $coerce_to = $cd->{coerce_to};

    if ($coerce_to eq 'float') {
        $cd->{_ccl_check_type} = "!ref($dt) && $dt >= 0 && $dt < 86400";
    } elsif ($coerce_to eq 'str_hms') {
        $cd->{_ccl_check_type} = "$dt =~ /\\A([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2})(?:\\.[0-9]{1,9})?\\z/";
    } elsif ($coerce_to eq 'Date::TimeOfDay') {
        $c->add_runtime_module($cd, 'Scalar::Util');
        $cd->{_ccl_check_type} = "Scalar::Util::blessed($dt) && $dt\->isa('Date::TimeOfDay')";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', use either ".
            "float, str_hms, or Date::TimeOfDay";
    }
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        # i'm lazy, technical debt
        $c->_die($cd, "timeofday's comparison with expression not yet supported");
    }

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'float') {
        if ($which eq 'is') {
            $c->add_ccl($cd, "$dt == $ct");
        } elsif ($which eq 'in') {
            $c->add_runtime_module($cd, 'List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{$dt == \$_}, $ct)");
        }
    } elsif ($coerce_to eq 'str_hms') {
        if ($which eq 'is') {
            $c->add_ccl($cd, "$dt eq $ct");
        } elsif ($which eq 'in') {
            $c->add_runtime_module($cd, 'List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{$dt eq \$_}, $ct)");
        }
    } elsif ($coerce_to eq 'Date::TimeOfDay') {
        if ($which eq 'is') {
            $c->add_ccl($cd, "Date::TimeOfDay->compare($dt, $ct)==0");
        } elsif ($which eq 'in') {
            $c->add_runtime_module($cd, 'List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{Date::TimeOfDay->compare($dt, \$_)==0}, $ct)");
        }
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        # i'm lazy, technical debt
        $c->_die($cd, "timeofday's comparison with expression not yet supported");
    }

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'float') {
        if ($which eq 'min') {
            $c->add_ccl($cd, "$dt >= $cv");
        } elsif ($which eq 'xmin') {
            $c->add_ccl($cd, "$dt > $cv");
        } elsif ($which eq 'max') {
            $c->add_ccl($cd, "$dt <= $cv");
        } elsif ($which eq 'xmax') {
            $c->add_ccl($cd, "$dt < $cv");
        } elsif ($which eq 'between') {
            $c->add_ccl($cd, "$dt >= $cv->[0] && $dt <= $cv->[1]");
        } elsif ($which eq 'xbetween') {
            $c->add_ccl($cd, "$dt >  $cv->[0] && $dt <  $cv->[1]");
        }
    } elsif ($coerce_to eq 'str_hms') {
        if ($which eq 'min') {
            $c->add_ccl($cd, "$dt ge '$cv'");
        } elsif ($which eq 'xmin') {
            $c->add_ccl($cd, "$dt gt '$cv'");
        } elsif ($which eq 'max') {
            $c->add_ccl($cd, "$dt le '$cv'");
        } elsif ($which eq 'xmax') {
            $c->add_ccl($cd, "$dt lt '$cv'");
        } elsif ($which eq 'between') {
            $c->add_ccl($cd, "$dt ge '$cv->[0]' && $dt le '$cv->[1]'");
        } elsif ($which eq 'xbetween') {
            $c->add_ccl($cd, "$dt gt '$cv->[0]' && $dt lt '$cv->[1]'");
        }
    } elsif ($coerce_to eq 'Date::TimeOfDay') {
        if ($which eq 'min') {
            $c->add_ccl($cd, "Date::TimeOfDay->compare($dt, $cv) >= 0");
        } elsif ($which eq 'xmin') {
            $c->add_ccl($cd, "Date::TimeOfDay->compare($dt, $cv) > 0");
        } elsif ($which eq 'max') {
            $c->add_ccl($cd, "Date::TimeOfDay->compare($dt, $cv) <= 0");
        } elsif ($which eq 'xmax') {
            $c->add_ccl($cd, "Date::TimeOfDay->compare($dt, $cv) < 0");
        } elsif ($which eq 'between') {
            $c->add_ccl($cd, "Date::TimeOfDay->compare($dt, $cv\->[0]) >= 0 && Date::TimeOfDay->compare($dt, $ct\->[1]) <= 0");
        } elsif ($which eq 'xbetween') {
            $c->add_ccl($cd, "Date::TimeOfDay->compare($dt, $cv\->[0]) >  0 && Date::TimeOfDay->compare($dt, $ct\->[1]) <  0");
        }
    }
}

1;
# ABSTRACT: perl's type handler for type "timeofday"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::perl::TH::timeofday - perl's type handler for type "timeofday"

=head1 VERSION

This document describes version 0.896 of Data::Sah::Compiler::perl::TH::timeofday (from Perl distribution Data-Sah), released on 2019-07-04.

=head1 DESCRIPTION

The C<timeofday> type can be represented using one of three choices: C<float>
(seconds after midnight), C<str_hms> (string in the form of hh:mm:ss), or
C<Date::TimeOfDay> (instance of L<Date::TimeOfDay> class). This choice can be
specified in the schema using clause attribute C<x.perl.coerce_to>, e.g.:

 ["date", "x.perl.coerce_to"=>"float"]
 ["date", "x.perl.coerce_to"=>"str_hms"]
 ["date", "x.perl.coerce_to"=>"Date::TimeOfDay"]

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$

=head1 COMPILATION DATA KEYS

=over

=item * B<coerce_to> => str

By default will be set to C<str_hms>.

=back

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
