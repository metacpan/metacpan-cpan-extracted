package Biblio::SIF::Patron;

use vars qw(@ISA);
@ISA = qw(Biblio::SIF);

use Biblio::SIF;

use constant BASE_SEGMENT_LEN    => 456;
use constant ADDRESS_SEGMENT_LEN => 429;

use overload q("") => \&as_string;

sub _min_length { BASE_SEGMENT_LEN }

sub id              { shift()->_numeric(  0, 10, @_ ) }

sub barcode1        { shift()->_string(  20, 25, @_ ) }
sub group1          { shift()->_string(  45, 10, @_ ) }
sub status1         { shift()->_string(  55,  1, @_ ) }

sub barcode2        { shift()->_string(  76, 25, @_ ) }
sub group2          { shift()->_string( 101, 10, @_ ) }
sub status2         { shift()->_string( 111,  1, @_ ) }

sub barcode3        { shift()->_string( 132, 25, @_ ) }
sub group3          { shift()->_string( 157, 10, @_ ) }
sub status3         { shift()->_string( 167,  1, @_ ) }

sub registration_date { shift()->_date( 178,     @_ ) }
sub expiration_date { shift()->_date(   188,     @_ ) }
sub purge_date      { shift()->_date(   198,     @_ ) }

sub institution_id  { shift()->_string( 238, 30, @_ ) }
sub ssn             { shift()->_string( 268, 11, @_ ) }

sub name_type       { shift()->_numeric(309,  1, @_ ) }
sub first_name      { shift()->_string( 340, 20, @_ ) }
sub middle_name     { shift()->_string( 360, 20, @_ ) }
sub last_name       { shift()->_string( 310, 30, @_ ) }
sub title           { shift()->_string( 380, 20, @_ ) }

sub historical_charges       { shift()->_numeric( 390, 10, @_ ) }
sub claims_return            { shift()->_numeric( 400,  5, @_ ) }
sub self_shelved             { shift()->_numeric( 405,  5, @_ ) }
sub lost_items               { shift()->_numeric( 410,  5, @_ ) }
sub late_media_returns       { shift()->_numeric( 415,  5, @_ ) }
sub historical_bookings      { shift()->_numeric( 420,  5, @_ ) }
sub cancelled_bookings       { shift()->_numeric( 425,  5, @_ ) }
sub unclaimed_bookings       { shift()->_numeric( 430,  5, @_ ) }
sub historical_call_slips    { shift()->_numeric( 435,  5, @_ ) }
sub historical_distributions { shift()->_numeric( 440,  5, @_ ) }
sub historical_short_loans   { shift()->_numeric( 445,  5, @_ ) }
sub unclaimed_short_loans    { shift()->_numeric( 450,  5, @_ ) }

sub num_addresses   { shift()->_numeric(455,  1, @_ ) }

# Convenience methods

sub last_first_name { join(', ', $_[0]->last_name, $_[0]->first_name) }
sub first_last_name { join(' ',  $_[0]->first_name, $_[0]->last_name) }

#sub _variable_segment {
#    my ($self) = @_;
#    my $n = $self->num_addresses;
#    my ($pos, $len) = (BASE_SEGMENT_LEN + $n * ADDRESS_SEGMENT_LEN, -1);
#    $self->_string($pos, $len, @_);
#}

sub notes {
    my $self = shift;
    my $n = $self->num_addresses;
    my $pos = BASE_SEGMENT_LEN + $n * ADDRESS_SEGMENT_LEN;
    my $len = length($$self) - $pos;
    $len -= length($1) if $$self =~ /([\x00\x0d]?\x0a)$/;
    if (@_) {
        my $str = join('', map { "\t1$_" } @_);  # XXX 1=General note
        substr($$self, $pos, $len) = $str;
    }
    else {
        my $str = substr($$self, $pos, $len);
        my @notes;
        push @notes, $1 while $str =~ /\G\t?([^\t]*)/gc;
        pop @notes while @notes && $notes[-1] eq '';
        return @notes;
    }
}

sub _barcode_segment {
    my $self = shift;
    my $i = shift;  # 1-based address number
    die if $i > 3;
    my ($pos, $len) = (BARCODE_SEGMENT_OFS + ($i-1) * BARCODE_SEGMENT_LEN, BARCODE_SEGMENT_LEN);
}

sub _address_segment {
    my $self = shift;
    my $i = shift;  # 1-based barcode number
    my ($pos, $len) = (BASE_SEGMENT_LEN + ($i-1) * ADDRESS_SEGMENT_LEN, ADDRESS_SEGMENT_LEN);
    if (@_) {
        substr($$self, $pos, $len) = shift;
    }
    else {
        return substr($$self, $pos, $len);
    }
}

sub address {
    my $self = shift;
    my $i = shift;
    if (@_) {
        my $address;
        if (@_ > 1) {
            $address = Biblio::SIF::Patron::Address->new(@_);
        }
        else {
            ($address) = @_;
        }
        $self->_address_segment($i, $address->as_string);
    }
    else {
        my $str = $self->_address_segment($i);
        return Biblio::SIF::Patron::Address->new(\$str);
    }
}

sub barcode {
    my $self = shift;
    my $i = shift;
    die "Bad barcode index; $i" if $i > 3;
    if (@_) {
        my $barcode;
        if (@_ > 1) {
            $barcode = Biblio::SIF::Patron::Barcode->new(@_);
        }
        else {
            ($barcode) = @_;
        }
        $self->_barcode_segment($i, $barcode->as_string);
    }
    else {
        my $str = $self->_barcode_segment($i);
        return Biblio::SIF::Patron::Barcode->new(\$str);
    }
}

sub barcodes {
    my $self = shift;
    die "Bad call" if @_;
    ($self->barcode1, $self->barcode2, $self->barcode3);
}

sub groups {
    my $self = shift;
    die "Bad call" if @_;
    my @groups = ($self->group1, $self->group2, $self->group3);
    wantarray ? @groups : join(',', @groups);
}

sub statuses {
    my $self = shift;
    die "Bad call" if @_;
    ($self->status1, $self->status2, $self->status3);
}

sub fields {
    qw(
        id
        barcode1 group1 status1
        barcode2 group2 status2
        barcode3 group3 status3
        expiration_date purge_date
        institution_id ssn
        name_type first_name middle_name last_name title
    );
}

sub as_hash {
    my ($self) = @_;
    my %h = map { $_ => $self->$_ } $self->fields;
    $h{'notes'} = [ $self->notes ];
    for (1..$self->num_addresses) {
        $h{"address$_"} = $self->address($_)->as_hash;
    }
    return \%h;
}

sub as_string {
    my ($self) = @_;
    return $$self;
}

# -------------------------------------------------------------------

package Biblio::SIF::Patron::Barcode;

use vars qw(@ISA);
@ISA = qw(Biblio::SIF);

use Biblio::SIF;

sub _min_length { 56 }

sub id              { shift()->_numeric(  0, 10, @_ ) }
sub barcode         { shift()->_string(  10, 25, @_ ) }
sub group           { shift()->_string(  35, 10, @_ ) }
sub status          { shift()->_string(  45,  1, @_ ) }
sub status_date     { shift()->_date(    46,     @_ ) }

sub fields {
    qw(
        id barcode group
        status status_date
    );
}

sub as_hash {
    my ($self) = @_;
    my %h = map { $_ => $self->$_ } $self->fields;
    return \%h;
}

# -------------------------------------------------------------------

package Biblio::SIF::Patron::Address;

use vars qw(@ISA);
@ISA = qw(Biblio::SIF);

use Biblio::SIF;

sub _min_length { 429 }

sub id              { shift()->_numeric(  0, 10, @_ ) }
sub type            { shift()->_numeric( 10,  1, @_ ) }
sub status          { shift()->_string(  11,  1, @_ ) }
sub begin_date      { shift()->_date(    12,     @_ ) }
sub end_date        { shift()->_date(    22,     @_ ) }
sub line1           { shift()->_string(  32, 50, @_ ) }
sub line2           { shift()->_string(  82, 40, @_ ) }
sub line3           { shift()->_string( 122, 40, @_ ) }
sub line4           { shift()->_string( 162, 40, @_ ) }
sub line5           { shift()->_string( 202, 40, @_ ) }
sub city            { shift()->_string( 242, 40, @_ ) }
sub state           { shift()->_string( 282,  7, @_ ) }
sub zipcode         { shift()->_string( 289, 10, @_ ) }
sub country         { shift()->_string( 299, 20, @_ ) }
sub phone           { shift()->_string( 319, 25, @_ ) }
sub cell_phone      { shift()->_string( 344, 25, @_ ) }
sub fax             { shift()->_string( 369, 25, @_ ) }
sub other_phone     { shift()->_string( 394, 25, @_ ) }
sub update_date     { shift()->_date(   419,     @_ ) }

sub postal_code     { shift()->_string( 289, 10, @_ ) }  # Alias
sub state_province  { shift()->_string( 282,  7, @_ ) }  # Alias
sub zip_postal      { shift()->_string( 289, 10, @_ ) }  # Alias

sub fields {
    qw(
        id type status
        begin_date end_date update_date
        line1 line2 line3 line4 line5
        city state zipcode country
        phone cell_phone fax other_phone
    );
}

sub as_hash {
    my ($self) = @_;
    my %h = map { $_ => $self->$_ } $self->fields;
    return \%h;
}

1;

=pod

=head1 NAME

Biblio::SIF::Patron - standard patron interchange file for Voyager ILS

=head1 SYNOPSIS

    use Biblio::SIF::Patron;
    $iter = Biblio::SIF::Patron->iterator(\*STDIN);
    while (my $patron = $iter->()) {
        $patron->institution_id($new_id);
        print $patron;
    }
