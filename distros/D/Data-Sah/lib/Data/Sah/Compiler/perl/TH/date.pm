package Data::Sah::Compiler::perl::TH::date;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;
use Scalar::Util qw(blessed looks_like_number);

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::date';

sub handle_type {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $dt = $cd->{data_term};

    $cd->{coerce_to} = $cd->{nschema}[1]{"x.perl.coerce_to"} // 'float(epoch)';

    my $coerce_to = $cd->{coerce_to};

    if ($coerce_to eq 'float(epoch)') {
        $cd->{_ccl_check_type} = "!ref($dt) && $dt =~ /\\A[0-9]+\\z/";
    } elsif ($coerce_to eq 'DateTime') {
        $c->add_runtime_module($cd, 'Scalar::Util');
        $cd->{_ccl_check_type} = "Scalar::Util::blessed($dt) && $dt\->isa('DateTime')";
    } elsif ($coerce_to eq 'Time::Moment') {
        $c->add_runtime_module($cd, 'Scalar::Util');
        $cd->{_ccl_check_type} = "Scalar::Util::blessed($dt) && $dt\->isa('Time::Moment')";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', use either ".
            "float(epoch), DateTime, or Time::Moment";
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
        $c->_die($cd, "date's comparison with expression not yet supported");
    }

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'float(epoch)') {
        if ($which eq 'is') {
            $c->add_ccl($cd, "$dt == $ct");
        } elsif ($which eq 'in') {
            $c->add_runtime_module($cd, 'List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{$dt == \$_}, $ct)");
        }
    } elsif ($coerce_to eq 'DateTime') {
        # we need to encode this because otherwise just dumping DateTime object
        # $cv will be unwieldy
        my $ect = "DateTime->from_epoch(epoch=>".$cv->epoch.")";

        if ($which eq 'is') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect)==0");
        } elsif ($which eq 'in') {
            $c->add_runtime_module($cd, 'List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{DateTime->compare($dt, \$_)==0}, $ect)");
        }
    } elsif ($coerce_to eq 'Time::Moment') {
        # we need to encode this because otherwise just dumping DateTime object
        # $cv will be unwieldy
        my $ect = "Time::Moment->from_epoch(".$cv->epoch.")";

        if ($which eq 'is') {
            $c->add_ccl($cd, "$dt\->compare($ect)==0");
        } elsif ($which eq 'in') {
            $c->add_runtime_module($cd, 'List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{$dt\->compare(\$_)==0}, $ect)");
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
        $c->_die($cd, "date's comparison with expression not yet supported");
    }

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'float(epoch)') {
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
    } elsif ($coerce_to eq 'DateTime') {
        # we need to encode this because otherwise just dumping DateTime object
        # $cv will be unwieldy
        my ($ect, $ect0, $ect1);
        if (ref($cv) eq 'ARRAY') {
            $ect0 = "DateTime->from_epoch(epoch=>".$cv->[0]->epoch.")";
            $ect1 = "DateTime->from_epoch(epoch=>".$cv->[1]->epoch.")";
        } else {
            $ect = "DateTime->from_epoch(epoch=>".$cv->epoch.")";
        }

        if ($which eq 'min') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect) >= 0");
        } elsif ($which eq 'xmin') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect) > 0");
        } elsif ($which eq 'max') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect) <= 0");
        } elsif ($which eq 'xmax') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect) < 0");
        } elsif ($which eq 'between') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect0) >= 0 && DateTime->compare($dt, $ect1) <= 0");
        } elsif ($which eq 'xbetween') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect0) >  0 && DateTime->compare($dt, $ect1) <  0");
        }
    } elsif ($coerce_to eq 'Time::Moment') {
        # we need to encode this because otherwise just dumping DateTime object
        # $cv will be unwieldy
        my ($ect, $ect0, $ect1);
        if (ref($cv) eq 'ARRAY') {
            $ect0 = "Time::Moment->from_epoch(".$cv->[0]->epoch.")";
            $ect1 = "Time::Moment->from_epoch(".$cv->[1]->epoch.")";
        } else {
            $ect = "Time::Moment->from_epoch(".$cv->epoch.")";
        }

        if ($which eq 'min') {
            $c->add_ccl($cd, "$dt\->compare($ect) >= 0");
        } elsif ($which eq 'xmin') {
            $c->add_ccl($cd, "$dt\->compare($ect) > 0");
        } elsif ($which eq 'max') {
            $c->add_ccl($cd, "$dt\->compare($ect) <= 0");
        } elsif ($which eq 'xmax') {
            $c->add_ccl($cd, "$dt\->compare($ect) < 0");
        } elsif ($which eq 'between') {
            $c->add_ccl($cd, "$dt\->compare($ect0) >= 0 && $dt\->compare($ect1) <= 0");
        } elsif ($which eq 'xbetween') {
            $c->add_ccl($cd, "$dt\->compare($ect0) >  0 && $dt\->compare($ect1) <  0");
        }
    }
}

1;
# ABSTRACT: perl's type handler for type "date"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::perl::TH::date - perl's type handler for type "date"

=head1 VERSION

This document describes version 0.897 of Data::Sah::Compiler::perl::TH::date (from Perl distribution Data-Sah), released on 2019-07-19.

=head1 DESCRIPTION

The C<date> type can be represented using one of three choices: int (epoch),
L<DateTime> object, or L<Time::Moment> object. This choice can be specified in
the schema using clause attribute C<x.perl.coerce_to>, e.g.:

 ["date", "x.perl.coerce_to"=>"float(epoch)"]
 ["date", "x.perl.coerce_to"=>"DateTime"]
 ["date", "x.perl.coerce_to"=>"Time::Moment"]

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$

=head1 COMPILATION DATA KEYS

=over

=item * B<coerce_to> => str

By default will be set to C<float(epoch)>. Other valid values include:
C<DateTime>, C<Time::Moment>.

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
