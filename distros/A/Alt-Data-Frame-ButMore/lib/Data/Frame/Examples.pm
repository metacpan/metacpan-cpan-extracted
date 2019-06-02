package Data::Frame::Examples;

# ABSTRACT: Example data sets

use Data::Frame::Setup;

use File::ShareDir qw(dist_dir);
use Module::Runtime qw(module_notional_filename);
use Path::Tiny;

use Data::Frame;
use Data::Frame::Util qw(factor);

use parent qw(Exporter::Tiny);

my %data_setup = (
    airquality => {},
    diamonds   => {
        postprocess => sub {
            my ($df) = @_;
            return _factorize(
                $df,
                cut     => [ 'Fair', 'Good', 'Very Good', 'Premium', 'Ideal' ],
                color   => [ 'D' .. 'J' ],
                clarity => [qw(I1 SI2 SI1 VS2 VS1 VVS2 VVS1 IF)]
            );
        }
    },
    economics      => { params => { dtype => { date => 'datetime' } } },
    economics_long => { params => { dtype => { date => 'datetime' } } },
    iris           => { params => { dtype => { Species => 'factor' } } },
    mpg            => {},
    mtcars         => {},
    txhousing      => {},
);
my @data_names = sort keys %data_setup;

our @EXPORT_OK   = ( @data_names, 'dataset_names' );
our %EXPORT_TAGS = (
    datasets => \@data_names,
    all      => \@EXPORT_OK,
);

my $data_raw_dir;

#TODO: Change this dist name when merging this to Data::Frame.
try { $data_raw_dir = dist_dir('Alt-Data-Frame-ButMore'); }
catch {
    # for dev env only
    my $path = path( $INC{ module_notional_filename(__PACKAGE__) } );
    $data_raw_dir =
      path( $path->parent( ( () = __PACKAGE__ =~ /(::)/g ) + 2 ), 'data-raw' )
      . '';
}

for my $name (@data_names) {
    no strict 'refs';
    *{$name} = _make_data( $name, $data_setup{$name} );
}


sub dataset_names { @data_names; }

sub _factorize {
    my ($df, %var_levels ) = @_;

    for my $var (sort keys %var_levels) {
        my $levels = $var_levels{$var};
        $df->set(
            $var,
            factor(
                $df->at($var),
                levels  => $levels,
                ordered => true
            )
        );
    }
    return $df;
};

#TODO: switch from csv to some other format for speed
sub _make_data {
    my ( $name, $setup ) = @_;

    return sub {
        state $df;
        unless ( defined $df ) {
            $df = Data::Frame->from_csv(
                "$data_raw_dir/$name.csv",
                header => true,
                %{ $setup->{params} }
            );
            if (my $postprocess = $setup->{postprocess}) {
                $df = $postprocess->($df);
            }
        }
        return $df;
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Examples - Example data sets

=head1 VERSION

version 0.0051

=head1 SYNOPSIS

    use Data::Frame::Examples qw(:datasets dataset_names);

    my $datasets = dataset_names();    # names of all example datasets

    my $mtcars = mtcars();

=head1 DESCRIPTION

Example datasets as L<Data::Frame> objects.

Checkout C<Data::Frame::Examples::dataset_names()> for an array of
example datasets provided by this module.

=head1 FUNCTIONS

=head2 dataset_names

Returns an array of names of the datasets in this module. 

=head1 DATASETS

=head2 airquality

A dataset with 154 observations on 6 variables,
for daily readings of the following air quality values for May 1, 1973 to
September 30, 1973.

The variables are,

=over 4

=item *

Ozone

numeric Ozone (ppb)

=item *

Solar_R

numeric Solar R (lang)

=item *

Wind

numeric Wind (mph)

=item *

Temp

numeric Temperature (degrees F)

=item *

Month

numeric Month (1-12)

=item *

Day

numeric Day of month (1-31)

=back

=head2 diamonds

A dataset containing the prices and other attributes of almost 53,940
diamonds on 10 variables.

The variables are,

=over 4

=item *

price

price in US dollars

=item *

carat

weight of the diamond

=item *

cut

quality of the cut (Fair, Good, Very Good, Premium, Ideal)

=item *

color

diamond colour, from J (worst) to D (best)

=item *

clarity

a measurement of how clear the diamond is
(I1 (worst), SI2, SI1, VS2, VS1, VVS2, VVS1, IF (best))

=item *

x

length in mm

=item *

y

width in mm

=item *

z

depth in mm

=item *

depth

total depth percentage = z / mean(x, y) = 2 * z / (x + y) (43–79)

=item *

table

width of top of diamond relative to widest point

=back

=head2 economics

A dataset with 574 rows and 6 variables, 
produced from US economic time series data available from
L<http://research.stlouisfed.org/fred2>.

The variables are,

=over 4

=item *

date

Month of data collection

=item *

psavert

personal saving rate

=item *

pce

personal consumption expenditures, in billions of dollars

=item *

unemploy

number of unemployed in thousands

=item *

uempmed

median duration of unemployment, in weeks

=item *

pop

total population, in thousands

=back

=head2 economics_long

A dataset with 2870 rows and 4 variables.

It's from the same data source as C<economics>, except that C<economics>
is in "wide" format, this C<economics_long> is in "long" format.

=head2 iris

A dataset with 150 cases and 5 variables, for 50 flowers from each of 3
species of iris.

The variables are,

=over 4

=item *

Sepal_Length

=item *

Sepal_Width

=item *

Petal_Length

=item *

Petal_Width

=item *

Species

The species are I<setosa>, I<versicolor>, and I<virginica>.

=back

=head2 mpg

A subset of the fuel economy data that the EPA makes available on
L<http://fueleconomy.gov>. 234 rows and 11 variables.

The variables are,

=over 4

=item *

manufacturer

=item *

model

model name

=item *

displ

Engine displacement, in litres

=item *

year

year of manufacture

=item *

cyl

number of cylinders

=item *

trans

type of transmission

=item *

drv

f = front-wheel drive, r = rear wheel drive, 4 = 4wd

=item *

cty

city miles per gallon

=item *

hwy

highway miles per gallon

=item *

fl

fuel type

=item *

class

"type" of car

=back

=head2 mtcars

Data extracted from the 1974 I<Motor Trend US> magazine, for 32 automobiles
(1973-74 models). 32 observations on 11 variables.

The variables are,

=over 4

=item *

mpg

Miles/(US) gallon

=item *

cyl

Number of cylinders

=item *

disp

Displacement (cu.in.)

=item *

hp

Gross horsepower

=item *

drat

Rear axle ratio

=item *

wt

Weight (1000 lbs)

=item *

qseq

1/4 mile time

=item *

vs

V/S

=item *

am

Transmission (0 = automatic, 1 = manual)

=item *

gear

Number of forward gears

=item *

carb

Number of carburetors

=back

=head2 txhousing

Information about the housing market in Texas provided by the TAMU real
estate center, L<http://recenter.tamu.edu/>.
8602 observations and 9 variables.

The variables are,

=over 4

=item *

city

Name of MLS area

=item *

year,month,date

=item *

sales

Number of sales

=item *

volume

Total value of sales

=item *

median

Median sale price

=item *

listings

Total active listings

=item *

inventory

"Months inventory": amount of time it would take to sell all current
listings at current pace of sales.

=back

=head1 SEE ALSO

L<Data::Frame>

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
