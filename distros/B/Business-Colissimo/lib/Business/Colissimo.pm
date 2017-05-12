package Business::Colissimo;

use 5.006;
use strict;
use warnings;

use Barcode::Code128;

=head1 NAME

Business::Colissimo - Shipping labels for ColiPoste

=head1 VERSION

Version 0.2200

=cut

our $VERSION = '0.2200';

my %product_codes = (access_f => '8L', 
		     expert_f => '8V', 
		     expert_om => '7A', 
		     expert_i => 'CY', 
		     expert_i_kpg => 'EY'
    );

my %test_account = (access_f => '964744', 
		    expert_f => '964744',
		    expert_om => '964744', 
		    expert_i => '964744', 
		    expert_kpg => '900000',  
    );

my %test_ranges = (access_f => [qw/4139207826 4139212825/],
		   expert_f => [qw/5649204247 5649209246/],
		   expert_om => [qw/5389439016 5389444015/],
		   expert_i => [qw/00005801 00055800/],
		   expert_i_kpg => [qw/00000001 00051000/],
		    );
		   
my %attributes = (parcel_number => 'parcel number', 
		  postal_code => 'postal code', 
		  customer_number => 'customer number',
		  weight => 'parcel weight',
		  not_mechanisable => 'not mechanisable',

		  # expert modes
		  cod => 'cash on delivery',
		  level => 'insurance/recommendation level',

          # expert_om/expert_i modes
          ack_receipt => 'acknowledgement of receipt',
          
          # expert_om mode
          duty_free => 'customs duty free (FTD)',
          
          # expert_i mode
          country_code => 'country code',
                  
		  # barcode image
		  scale => 'barcode image scale factor',
		  height => 'barcode image height',
		  padding => 'barcode image padding',

		  # testing
		  test => 'testing',
    );

my %logo_files = (access_f => 'AccessF',
		  expert_f => 'ExpertF',
		  expert_om => 'ExpertOM',
		  expert_i => 'ExpertInter',
		  expert_i_kpg => 'ExpertInter',                  
    );

my %countries = (AT => {epg => 1},
                 AU => {kpg => 1},
                 BE => {epg => 1},
                 BR => {kpg => 1},
                 CH => {epg => 1},
                 CN => {kpg => 1},
                 DE => {epg => 1},
                 DK => {epg => 1},
                 ES => {epg => 1},
                 FI => {epg => 1},
                 FR => {epg => 1},
                 GB => {epg => 1},
                 GR => {epg => 1},
                 HK => {kpg => 1},
                 IE => {epg => 1},
                 IL => {kpg => 1},
                 IS => {epg => 1},
                 IT => {epg => 1},
                 JP => {kpg => 1},
                 KR => {kpg => 1},
                 LU => {epg => 1},
                 MA => {kpg => 1},
                 NO => {epg => 1},
                 PT => {epg => 1},
                 RU => {kpg => 1},
                 SG => {kpg => 1},
                 SE => {epg => 1},
                 VN => {kpg => 1},
                 US => {kpg => 1},
    );

=head1 SYNOPSIS 

    use Business::Colissimo;

    $colissimo = Business::Colissimo->new(mode => 'access_f',
                               customer_number => '900001',
                               parcel_number => '2052475203',
                               postal_code => '72240',
                               weight => 120);

    # get logo file name
    $colissimo->logo;

    # produce barcode images
    $colissimo->barcode('tracking', spacing => 1);
    $colissimo->barcode('shipping', spacing => 1);

    # customer number
    $colissimo->customer_number('900001')
    # parcel number from your alloted range numbers
    $colissimo->parcel_number('2052475203');

    # country code for recipient (expert_i and expert_i_kpg mode)
    $colissimo->country_code('DE');

    # postal code for recipient
    $colissimo->postal_code('72240');

    # add weight in grams
    $colissimo->weight(250);

    # not mechanisable option
    $colissimo->not_mechanisable(1);
    
    # cash on delivery option (expert mode only)
    $colissimo->cod(1);

    # insurance level (expert mode only)
    $colissimo->level('01');

    # recommendation level (expert_f and expert_om mode only)
    $colissimo->level('21');

    # set scale in pixels for barcode image (default: 1)
    $colissimo->scale(2);

    # set height in pixels for barcode image (default: 77)
    $colissimo->height(100);

=head1 DESCRIPTION

Business::Colissimo helps you to produce shipping labels
for the following ColiPoste services:

=over 4

=item Access France
    
    $colissimo = Business::Colissimo->new(mode => 'access_f');

=item Expert France

    $colissimo = Business::Colissimo->new(mode => 'expert_f');

=item Expert Outre Mer

    $colissimo = Business::Colissimo->new(mode => 'expert_om');

=item Expert International

    KPG countries:

    $colissimo = Business::Colissimo->new(mode => 'expert_i_kpg');

    Countries outside of KPG:

    $colissimo = Business::Colissimo->new(mode => 'expert_i');

=back

=head1 METHODS

=head2 new

    $colissimo = Business::Colissimo->new(mode => 'access_f',
         customer_number => '900001',
         parcel_number => '2052475203',
         postal_code => '72240',
         weight => 250);

    $colissimo = Business::Colissimo->new(mode => 'expert_f',
         customer_number => '900001',
         parcel_number => '2052475203',
         postal_code => '72240',
         weight => 250,
         cod => 1,
         level => '01');

=cut

sub new {
    my ($class, $self, %args);

    $class = shift;
    %args = @_;

    unless (defined $args{mode} && $product_codes{$args{mode}}) {
	die 'Please select valid mode for ', __PACKAGE__;
    }

    $self = {mode => delete $args{mode},
	     parcel_number => '',
         country_code => '',
	     postal_code => '',
	     customer_code => '',
	     not_mechanisable => '0',

	     # expert 
	     cod => '0',
	     level => '00',
         ack_receipt => '0',
         duty_free => '0',

         # barcode image
	     scale => 1,
	     height => 77,
             padding => 20,

	     # testing
	     test => 0,
    };

    if ($self->{mode} eq 'expert_i' || $self->{mode} eq 'expert_i_kpg') {
        $self->{international} = 1;
    }
    else {
        $self->{international} = 0;
    }
    
    bless $self, $class;

    for my $name (keys %args) {
	if (exists $attributes{$name}) {
	    $self->$name($args{$name});
	}
    }

    return $self;
}

=head2 barcode

Produces the tracking barcode:

    $colissimo->barcode('tracking');

Same with proper spacing for the shipping label:

    $colissimo->barcode('tracking', spacing => 1);

Produces the sorting barcode:

    $colissimo->barcode('sorting');

Same with proper spacing for the shipping label:

    $colissimo->barcode('sorting', spacing => 1);

=cut

sub barcode {
    my ($self, $type, %args) = @_;
    my ($barcode, $parcel_number, $control);

    $barcode = $product_codes{$self->{mode}};

    unless (length($self->{parcel_number})) {
        die "Missing $attributes{parcel_number}";
    }
    
    if ($type eq 'sorting') {
        # check if we have everything we need
        my @required = qw/postal_code parcel_number customer_number weight/;

        if ($self->{international}) {
            push (@required, 'country_code');
        }
        
        for my $name (@required) {
            unless (length($self->{$name})) {
                die "Missing $attributes{$name} for mode $self->{mode}";
            }
        }
        
        # fixed sort code
        if ($self->{international}) {
            $barcode .= '2';
        }
        else {
            $barcode .= '1';
        }
        
        if ($self->{international}) {
            # recipient country code
            $barcode .= $self->country_code;

            # recipient postal code (first three characters, filled with zeroes if necessary)
            my $postal = $self->postal_code;

            if (length($postal) >= 3) {
                $barcode .= substr($postal, 0, 3);
            }
            else {
                $barcode .= $postal . ('0' x (3 - length($postal)));
            }
        }
        else {
            # recipient postal code
            $barcode .= $self->postal_code;
        }
        
        # customer code
        $control = $self->customer_number;

        # parcel weight
        $control .= $self->weight;

        # insurance/recommendation level
        $control .= $self->level;

        # not mechanisable 
        $control .= $self->not_mechanisable;

        if ($self->{mode} eq 'expert_om'
            || $self->international) {
            # combination of cash on delivery, customs duty free
            # and acknowledgement of receipt options
            $control .= $self->cod 
                + 2 * $self->duty_free
                + 4 * $self->ack_receipt;
        }
        else {
            # cash on delivery
            $control .= $self->cod;
        }

        # control link digit (last digit of parcel number)
        if ($self->international) {
            $control .= substr($self->parcel_number, 7, 1);
        } else {
            $control .= substr($self->parcel_number, 9, 1);
        }
    
        $barcode .= $control . $self->control_key($control);
    
  
        if ($args{spacing}) {
            return join(' ', substr($barcode, 0, 3),
                        substr($barcode, 3, 5),
                        substr($barcode, 8, 6),
                        substr($barcode, 14, 4),
                        substr($barcode, 18, 6));
        }
    }
    else {
        $parcel_number = $self->parcel_number;
        $barcode .= $parcel_number;
        $barcode .= $self->control_key($parcel_number);

        if ($self->{international} && $type eq 'tracking') {
            $barcode .= 'FR';
        }
   
        if ($args{spacing}) {
            if ($self->{international}) {
                return join(' ', substr($barcode, 0, 2),
                            substr($barcode, 2, 4),
                            substr($barcode, 6, 4),
                            substr($barcode, 10, 3));
            }
            else {
                return join(' ', substr($barcode, 0, 2),
                            substr($barcode, 2, 5),
                            substr($barcode, 7, 5),
                            substr($barcode, 12, 1));
            }
        }
    }

    return $barcode;
}

=head2 barcode_image

Produces PNG image for tracking barcode:

    $colissimo->barcode_image('tracking');

Produces PNG image for sorting barcode:

    $colissimo->barcode_image('sorting');

Produces PNG image for arbitrary barcode:

    $colissimo->barcode_image('8L20524752032');

The scale of the image can be changed for each
barcode individually:

    $colissimo->barcode_image('8L20524752032', scale => 2);

The default scale is set to 1, because that produces
images with the right number of pixels to include them
into PDF with L<PDF::API2>, which uses 72dpi resolution
for images unless you specify width and height explicitly
(see L<PDF::API2::Content>).

The formula for calculating width in mm for a 72dpi
resolution is as follows:

    (1px * 25.4) / 72dpi

This fits into Colissimo's requirement for the basic
module (narrowest element of the bar code) of 
0.33 to 0.375 mm.

=cut

sub barcode_image {
    my ($self, $type, %args) = @_;
    my ($barcode, $image, $code128, $png, $scale, $height, $padding);

    if ($type eq 'tracking' || $type eq 'sorting') {
	$barcode = $self->barcode($type);
    }
    else {
	$barcode = $type;
    }

    $code128 = Barcode::Code128->new;
    $code128->border(0);

    # scale
    if ($scale = $self->{scale} || $args{scale}) {
	$code128->scale($scale);
    }

    # height 
    if ($height = $self->{height} || $args{height}) {
	$code128->height($height);
    }

    # padding
    $padding = $self->{padding} || $args{padding};
    $code128->padding($padding);

    $code128->show_text(0);

    $png = $code128->png($barcode);
}


=head2 logo

Returns logo file name for selected service.

    $colissimo->logo;

=cut

sub logo {
    my $self = shift;

    return $logo_files{$self->{mode}} . '.bmp';
}

=head2 test

Toggles testing.

    $colissimo->test(1);

=cut

sub test {
    my $self = shift;

    if (@_ > 0 && defined $_[0]) {
	$self->{test} = $_[0];
	
	if ($self->{test} && ! $self->{customer_number}) {
	    # use predefined customer number for tests
	    $self->{customer_number} = $test_account{$self->{mode}};
	}
    }

    return $self->{test};
}

=head2 scale

Get current scale for barcode image:

    $colissimo->scale;

Set current scale for barcode image:

    $colissimo->scale(3);

=cut

sub scale {
    my $self = shift;
    my $scale;

    if (@_ > 0 && defined $_[0]) {
	$scale = $_[0];

	if ($scale !~ /^\d+$/) {
	    die 'Please provide valid scale factor';
	}

	$self->{scale} = $scale;
    }

    return $self->{scale};
}

=head2 height

Get current height for barcode image:

    $colissimo->height;

Set current height for barcode image:

    $colissimo->height(100);

=cut

sub height {
    my $self = shift;
    my $height;

    if (@_ > 0 && defined $_[0]) {
	$height = $_[0];

	if ($height !~ /^\d+$/) {
	    die 'Please provide valid height';
	}

	$self->{height} = $height;
    }

    return $self->{height};
}

=head2 padding

Get current padding for barcode image:

    $colissimo->padding;

Set current padding for barcode image:

    $colissimo->padding(0);

=cut

sub padding {
    my $self = shift;
    my $padding;

    if (@_ > 0 && defined $_[0]) {
	$padding = $_[0];

	if ($padding !~ /^\d+$/) {
	    die 'Please provide valid padding';
	}

	$self->{padding} = $padding;
    }

    return $self->{padding};
}

=head2 customer_number

Get current customer number:

    $colissimo->customer_number;

Set current customer number:

    $colissimo->customer_number('900001');

=cut

sub customer_number {
    my $self = shift;
    my $number;

    if (@_ > 0 && defined $_[0]) {
	$number = $_[0];
	
        $number =~ s/\s+//g;

	if ($number !~ /^\d{6}$/) {
	    die 'Please provide valid customer number (6 digits) for barcode';
	}

	$self->{customer_number} = $number;
    }    

    return $self->{customer_number};
}

=head2 parcel_number

Get current parcel number:

    $colissimo->parcel_number;
    
Set current parcel number:

    $colissimo->parcel_number('2052475203');

=cut

sub parcel_number {
    my $self = shift;
    my $number;

    if (@_ > 0 && defined $_[0]) {
        $number = $_[0];
	
        $number =~ s/\s+//g;

        if ($self->{international}) {
            if ($number !~ /^\d{8}$/) {
                die 'Please provide valid parcel number (8 digits) for barcode';
            }
        }
        else {
            if ($number !~ /^\d{10}$/) {
                die 'Please provide valid parcel number (10 digits) for barcode';
            }
        }
        
        $self->{parcel_number} = $number;
    }

    return $self->{parcel_number};
}

=head2 country_code

Get current country code:

    $colissimo->country

Set current country code:

    $colissimo->country('BE');

The country code is defined in the ISO 3166 standard.

Switches to expert_i_kpg mode automatically.

=cut

sub country_code {
    my $self = shift;
    my $string;

    if (@_ > 0 && defined $_[0]) {
        $string = uc($_[0]);
        $string =~ s/\s+//g;

        if ($string !~ /^[A-Z]{2}$/) {
            die 'Please provide valid country code for barcode';
        }

        if ($self->{mode} eq 'access_f'
            || $self->{mode} eq 'expert_f') {
            if ($string ne 'FR') {
                die "Only France is allowed as delivery country for $self->{mode}.\n";
            }
        }
        elsif ($self->{mode} eq 'expert_om') {
            # no country code requirements yet
        }
        elsif ($string eq 'FR') {
            die "France isn't allowed as delivery country for $self->{mode}.\n";
        }

        if (exists $countries{$string} && $countries{$string}->{kpg}) {
            $self->{mode} = 'expert_i_kpg';
        }
        
        $self->{country_code} = $string;
    }

    return $self->{country_code};
}

=head2 postal_code

Get current postal code:

    $colissimo->postal_code

Set current postal code:

    $colissimo->postal_code('72240');

=cut

sub postal_code {
    my $self = shift;
    my $string; 

    if (@_ > 0 && defined $_[0]) {
        $string = $_[0];
	
        $string =~ s/\s+//g;

        if ($self->{international}) {
            if ($string eq '0' || $string !~ /^[A-Z0-9]{1,10}$/) {
                die 'Please provide valid postal code (1-10 alphanumerics) for barcode';
            }
        }
        else {
            if ($string !~ /^[A-Z0-9]{5}$/) {
                die 'Please provide valid postal code (5 alphanumerics) for barcode';
            }
        }
        
        $self->{postal_code} = $string;
    }

    return $self->{postal_code};
}

=head2 weight

Get current weight:

   $colissimo->weight;

Set weight in grams:

   $colissimo->weight(250);

=cut

sub weight {
    my $self = shift;
    my $number;

    if (@_ > 0 && defined $_[0]) {
	$number = $_[0];
	
        $number =~ s/\s+//g;

	if ($number !~ /^\d{1,5}$/) {
	    die 'Please provide valid parcel weight (less than 100 kg) for barcode';
	}

	$self->{weight} = sprintf('%04d', int($number / 10));
    }

    return $self->{weight};
}

=head2 not_mechanisable

Get current value of not mechanisable option:

    $colissimo->not_mechanisable;

Set current value of not mechanisable option:

    $colissimo->not_mechanisable(1);

Possible values are 0 (No) and 1 (Yes).

=cut

sub not_mechanisable {
    my $self = shift;
    my $number;

    if (@_ > 0 && defined $_[0]) {
	$number = $_[0];
	
        $number =~ s/\s+//g;

	if ($number !~ /^[01]$/) {
	    die 'Please provide valid value for not mechanisable (0 or 1)';
	}

	$self->{not_mechanisable} = $number;
    }

    return $self->{not_mechanisable};
}

=head2 cod

Get current value of cash on delivery option:

    $colissimo->cod;

Set current value of cash on delivery option:

    $colissimo->cod(1);

The cash on delivery option is available only in export mode,
possible values are 0 (No) and 1 (Yes).

=cut

sub cod {
    my $self = shift;
    my $number;

    if (@_ > 0 && defined $_[0]) {
	$number = $_[0];
	
        $number =~ s/\s+//g;

	if ($number !~ /^[01]$/) {
	    die 'Please provide valid value for cash on delivery option (0 or 1)';
	}

	if ($self->{mode} eq 'access' 
	    && $number eq '1') {
	    die 'Cash on delivery option not available in access mode.';
	}

	$self->{cod} = $number;
    }

    return $self->{cod};
}

=head2 level

Get current insurance resp. recommendation level:

    $colissimo->level;

Set current insurance resp. recommendation level:

    $colissimo->level('O1');
    $colissimo->level('21');

The level option is only available in expert mode, 
possible values are 01 ... 10 for insurance level
and 21 ... 23 for recommendation level.

=cut

sub level {
    my $self = shift;
    my $number;

   if (@_ > 0 && defined $_[0]) {
	$number = $_[0];
	
        $number =~ s/\s+//g;

	if ($number !~ /^(0\d|10|2[123])$/ ) {
	    die 'Please provide valid value for insurance/recommendation level.';
	}

	if ($self->{mode} eq 'access_f' 
	    && $number ne '00') {
	    die 'Insurance/recommendation level not available in access mode.';
	}

	$self->{level} = $number;
    }

    return $self->{level};
}

=head2 ack_receipt

Get current value for acknowledgement of receipt (AR):

    $colissimo->ack_receipt;

Set current value for acknowledgement of receipt (AR):

    $colissimo->ack_receipt(1);

Returns 1 if acknowledgement of receipt is enabled, 0 otherwise.

The ack_receipt option is only available in expert_om and expert_i modes,
possible values are 0 (No) and 1 (Yes).

=cut

sub ack_receipt {
    my $self = shift;
    my $number;

    if (@_ > 0 && defined $_[0]) {
        $number = $_[0];
        $number =~ s/\s+//g;

        if ($number !~ /^[01]$/) {
            die 'Please provide valid value for acknowledgement of receipt option (0 or 1)';
        }

        unless ($number == 0 || $self->international || $self->{mode} eq 'expert_om') {
            die 'Acknowledgement of receipt option only available in expert_om and expert_i modes.';
        }
        
        $self->{ack_receipt} = $number;
    }

    return $self->{ack_receipt};
}

=head2 duty_free

Get current value for customs duty free (FTD):

    $colissimo->duty_free;

Set current value for customs duty free (FTD):

    $colissimo->duty_free(1);

The custom duty free option is only available in expert_om mode,
possible values are 0 (No) and 1 (Yes).

=cut

sub duty_free {
    my $self = shift;
    my $number;

    if (@_ > 0 && defined $_[0]) {
        $number = $_[0];
        $number =~ s/\s+//g;

        if ($number !~ /^[01]$/) {
            die 'Please provide valid value for customs duty free option (0 or 1)';
        }

        unless ($number == 0 || $self->{mode} eq 'expert_om') {
            die 'Customs duty free option only available in expert_om mode.';
        }
        
        $self->{duty_free} = $number;
    }
    
    return $self->{duty_free};
}

=head2 international

Returns 1 on international (expert_i or expert_i_kpg) shippings,
0 otherwise.

=cut

sub international {
    return $_[0]->{international};
}

=head2 organisation

Returns the acronym of the inter-postal organisation (KPG or EPG)
corresponding to the destination country.

=cut

sub organisation {
    my $self = shift;
    
    if (exists $countries{$self->{country_code}}) {
        my $cref = $countries{$self->{country_code}};

        if ($cref->{epg}) {
            return 'EPG';
        }

        if ($cref->{kpg}) {
            return 'KPG';
        }
    }

    return '';
}

=head2 control_key

Returns control key for barcode.

=cut

sub control_key {
    my ($self, $characters) = @_;
    my (@codes, $even, $odd, $key, $mod);

    @codes = split(//, $characters);

    if ($self->international && @codes == 8) {
        # special case for tracking control keys
        # for international orders
        my @coefficients = (8, 6, 4, 2, 3, 5, 9, 7);

        while (@codes) {
            $key += shift(@codes) * shift(@coefficients);
        }

        $mod = $key % 11;

        if ($mod == 0) {
            return 5;
        }
        elsif ($mod == 1) {
            return 0;
        }
        else {
            return 11 - $mod;
        }
    }
    
    if (@codes % 2) {
	# pad characters for sorting control key
	unshift (@codes, '0');
    }

    while (@codes) {
	$odd += shift(@codes);
	$even += shift(@codes);
    }

    $key = (3 * $even) + $odd;
    $mod = $key % 10;

    return $mod ? 10 - $mod : 0;
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-colissimo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-Colissimo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::Colissimo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-Colissimo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-Colissimo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-Colissimo>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-Colissimo/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Ton Verhagen for being a big supporter of my projects in all aspects.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Business::Colissimo
