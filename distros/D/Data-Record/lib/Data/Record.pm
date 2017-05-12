package Data::Record;

use warnings;
use strict;

=head1 NAME

Data::Record - "split" on steroids

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
use constant NOT_FOUND    => -1;
use constant ALL_RECORDS  => -1;
use constant TRIM_RECORDS => 0;

=head1 SYNOPSIS

  use Regexp::Common;
  use Data::Record;
  my $record = Data::Record->new({
    split  => "\n",
    unless => $RE{quoted},
  });
  my @data = $record->records($data);

=head1 DESCRIPTION

Sometimes we need data split into records and a simple split on the input
record separator (C<$/>) or some other value fails because the values we're
splitting on may allowed in other parts of the data.  Perhaps they're quoted.
Perhaps they're embedded in other data which should not be split up.

This module allows you to specify what you wish to split the data on, but also
speficy an "unless" regular expression.  If the text in question matches the
"unless" regex, it will not be split there.  This allows us to do things like
split on newlines unless newlines are embedded in quotes.

=head1 METHODS

=head2 new

Common usage:

 my $record = Data::Record->new({
    split  => qr/$split/,
    unless => qr/$unless/,
 });

Advanced usage:

 my $record = Data::Record->new({
    split  => qr/$split/,
    unless => qr/$unless/,  # optional
    token  => $token,       # optional
    chomp  => 0,            # optional
    limit  => $limit,       # optional (do not use with trim)
    trim   => 1,            # optional (do not use with limit)
    fields => {
        split  => ',',
        unless => $RE{quoted}, # from Regexp::Common
    }
 });

The constructor takes a hashref of key/value pairs to set the behavior of data
records to be created.

=over 4
    
=item * split

This is the value to split the data on.  It may be either a regular expression
or a string.

Defaults to the current input record separator (C<$/>).

=item * unless

Data will be split into records matching the split value I<unless> they also
match this value.  No default.

If you do not have an C<unless> value, use of this module is overkill.

=item * token

You will probably never need to set this value.

Internally, this module attempts to find a token which does not match any text
found in the data to be split and also does not match the split value.  This is
necessary because we mask the data we don't want to split using this token.
This allows us to split the resulting text.

In the unlikely event that the module cannot find a token which is not in the
text, you may set the token value yourself to some string value.  Do not set it
to a regular expression.

=item * chomp

By default, the split value is discarded (chomped) from each record.  Set this
to a true value to keep the split value on each record.  This differs slightly
from how it's done with split and capturing parentheses:

  split /(\,)/, '3,4,5';

Ordinarily, this results in the following list:

 ( 3, ',', 4, ',', 5 )

This module assumes you want those values I<with> the preceding record.  By
setting chomp to false, you get the following list:

 ( '3,', '4,' 5 )

=item * limit

The default split behavior is similar to this:

 split $split_regex, $data;

Setting C<limit> will cause the behavior to act like this:

 split $split_regex, $data, $limit

See C<perldoc -f split> for more information about the behavior of C<limit>.

You may not set both C<limit> and C<trim> in the constructor.

=item * trim

By default, we return all records.  This means that due to the nature of split
and how we're doing things, we sometimes get a trailing null record.  However,
setting this value causes the module to behave as if we had done this:

 split $split_regex, $data, 0;

When C<split> is called with a zero as the third argument, trailing null values
are discarded.  See C<perldoc -f split> for more information.

You may not set both C<limit> and C<trim> in the constructor.

B<Note>:  This does I<not> trim white space around returned records.

=item * fields

By default, individual records are returned as strings.  If you set C<fields>,
you pass in a hashref of arguments that are identical to what C<new> would take
and resulting records are returned as array references processed by a new
C<Data::Record> instance.

Example:  a quick CSV parser which assumes that commas and newlines may both be
in quotes:

 # four lines, but there are only three records! (newline in quotes)
 $data = <<'END_DATA';
 1,2,"programmer, perl",4,5
 1,2,"programmer,
 perl",4,5
 1,2,3,4,5
 END_DATA
  
 $record = $RECORD->new({
     split  => "\n",
     unless => $quoted,
     trim   => 1,
     fields => {
         split  => ",",
         unless => $quoted,
     }
 });
 my @records = $record->records($data);
 foreach my $fields (@records) {
   foreach my $field = (@$fields);
     # do something
   }
 }

Note that above example will not remove the quotes from individual fields.

=back

=cut

sub new {
    my ( $class, $value_of ) = @_;
    my %value_of = %$value_of;

    # XXX fix this later after we have the core working
    my $self = bless {}, $class;

    unless ( exists $value_of{split} ) {
        $value_of{split} = $/;
    }
    $self->split( $value_of{split} )->unless( $value_of{unless} )
      ->chomp( exists $value_of{chomp} ? $value_of{chomp} : 1 )
      ->limit( exists $value_of{limit} ? $value_of{limit} : ALL_RECORDS );
    $self->token( $value_of{token} ) if exists $value_of{token};
    if ( exists $value_of{trim} ) {
        $self->_croak("You may not specify 'trim' if 'limit' is specified")
          if exists $value_of{limit};
        $self->trim(1);
    }
    $self->_fields( $value_of{fields} ) if exists $value_of{fields};
    return $self;
}

##############################################################################

=head2 split

  my $split = $record->split;
  $record->split($on_value);

Getter/setter for split value.  May be a regular expression or a scalar value.

=cut

sub split {
    my $self = shift;
    return $self->{split} unless @_;

    my $split = shift;
    $split = qr/\Q$split\E/ unless 'Regexp' eq ref $split;
    $self->{split} = $split;
    return $self;
}

##############################################################################

=head2 unless

 my $unless = $self->unless;
 $self->unless($is_value);

Getter/setter for unless value.  May be a regular expression or a scalar value.

=cut

sub unless {
    my $self = shift;
    return $self->{unless} unless @_;

    my $unless = shift;
    $unless = '' unless defined $unless;
    $unless = qr/\Q$unless\E/
      unless 'Regexp'     eq ref $unless
      || 'Regexp::Common' eq ref $unless;
    $self->{unless} = $unless;
    return $self;
}

##############################################################################

=head2 chomp

  my $chomp = $record->chomp;
  $record->chomp(0);

Getter/setter for boolean chomp value.

=cut

sub chomp {
    my $self = shift;
    return $self->{chomp} unless @_;

    $self->{chomp} = shift;
    return $self;
}

##############################################################################

=head2 limit

  my $limit = $record->limit;
  $record->limit(3);

Getter/setter for integer limit value.

=cut

sub limit {
    my $self = shift;
    return $self->{limit} unless @_;

    my $limit = shift;
    unless ( $limit =~ /^-?\d+$/ ) {
        $self->_croak("limit must be an integer value, not ($limit)");
    }
    $self->{limit} = $limit;
    return $self;
}

##############################################################################

=head2 trim

  my $trim = $record->trim;
  $record->trim(1);

Getter/setter for boolean limit value.  Setting this value will cause any
previous C<limit> value to be overwritten.

=cut

sub trim {
    my $self = shift;
    return $self->{trim} unless @_;

    my $limit = shift;
    $self->{limit} = $limit ? TRIM_RECORDS : ALL_RECORDS;
}

##############################################################################

=head2 token

  my $token = $record->token;
  $record->token($string_not_found_in_text);

Getter/setter for token value.  Token must be a string that does not match the
split value and is not found in the text.

You can return the current token value if you have set it in your code.  If you
rely on this module to create a token (this is the normal behavior), it is not
available via this method until C<records> is called.

Setting the token to an undefined value causes L<Data::Record> to try and find
a token itself.

If the token matches the split value, this method will croak when you attempt
to set the token.

If the token is found in the data, the C<records> method will croak when it is
called.

=cut

sub token {
    my $self = shift;
    return $self->{token} unless @_;

    my $token = shift;
    if ( defined $token ) {
        if ( $token =~ $self->split ) {
            $self->_croak(
                "Token ($token) must not match the split value (@{[$self->split]})"
            );
        }
    }
    $self->{token} = $token;
    return $self;
}

##############################################################################

=head2 records

  my @records = $record->records($data);

Returns C<@records> for C<$data> based upon current split criteria.

=cut

sub records {
    my ( $self, $data ) = @_;
    my $token = $self->_create_token($data);
    my @values;
    if ( defined( my $unless = $self->unless ) ) {
        my $index = 0;
        $data =~ s{($unless)}
            {
                $values[$index] = $1; 
                $token . $index++ . $token;
            }gex;

        #main::diag($data);
    }
    my $split = $self->split;
    $split = $self->chomp ? $split : qr/($split)/;

    # if they have a numeric split value, we don't want to split tokens
    my $token_re = qr/\Q$token\E/;
    $split = qr/(?<!$token_re)$split(?!$token_re)/
      if 0 =~ $split;
    my @records = split $split, $data, $self->limit;
    unless ( $self->chomp ) {
        my @new_records;
        while ( defined( my $record = shift @records ) ) {
            if (@records) {
                $record = join '', $record, shift @records;
            }
            push @new_records, $record;
        }
        @records = @new_records;
    }

    foreach my $record (@records) {
        unless ( NOT_FOUND eq index $record, $token ) {
            $record =~ s{$token_re(\d+)$token_re}{$values[$1]}gex;
        }
    }
    if ( my $field = $self->_fields ) {
        $_ = [ $field->records($_) ] foreach @records;
    }
    return @records;
}

sub _fields {
    my $self = shift;
    return $self->{fields} unless @_;

    my $fields = ref($self)->new(shift);
    if ( defined( my $token = $self->token ) ) {
        $fields->token($token);
    }
    $self->{fields} = $fields;
    return $self;
}

my @tokens = map { $_ x 6 } qw( ~ ` ? " { } ! @ $ % ^ & * - _ + = );

sub _create_token {
    my ( $self, $data ) = @_;
    my $token;
    if ( defined( $token = $self->token ) ) {
        $self->_croak("Current token ($token) found in data")
          unless NOT_FOUND eq index $data, $token;
    }

    foreach my $curr_token (@tokens) {
        if ( NOT_FOUND eq index $data, $curr_token ) {
            $token = $curr_token;
            $self->token($token);
            last;
        }
    }
    if ( defined $token ) {
        return $token;
    }

    my $tried = join ", ", @tokens;
    $self->_croak(
        "Could not determine a unique token for data.  Tried ($tried)");
}

sub _croak {
    my ( $self, $message ) = @_;
    require Carp;
    Carp::croak($message);
}

=head1 BUGS

It's possible to get erroneous results if the split value is C</\d+/>.  I've
tried to work around this.  Please let me know if there is a problem.

=head1 CAVEATS

This module must read I<all> of the data at once.  This can make it slow for
larger data sets.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid [at] cpan [dot] org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-record@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Record>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to the Monks for inspiration from
L<http://perlmonks.org/index.pl?node_id=492002>.

0.02 Thanks to Smylers and Stefano Rodighiero for catching POD errors.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Data::Record
