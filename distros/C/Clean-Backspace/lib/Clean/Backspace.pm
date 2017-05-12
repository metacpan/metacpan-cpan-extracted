package Clean::Backspace;

use strict;
use warnings;

our $VERSION = '1.03';

# create new object
sub new {

    # class name
    my $class = shift;

    # allocate memory
    my $self  = {};

    # assign object to class
    bless($self, $class);

    # return object reference
    return $self;
}

# backspace method
sub backspace {

    # object reference
    my $self = shift;

    # loop through list of array references
    for (@_){

        # loop through string references
        for (@$_){

            # convert string to ascii decimal values and reverse order 
            my @tmp = unpack("C*", reverse($$_));

            # delete character count
            my $del = 0;

            # new string
            my @new;

            # loop through character ascii values
            for (@tmp){

                # look for ascii 8 backspace 
                if ($_ == 8){

                    # increment number of characters to delete
                    $del++;

                    # skip over this character
                    next;
                }

                # check if any characters to delete
                elsif ($del != 0){

                    # decrement number of characters to delete 
                    $del--;

                    # skip over this character
                    next;
                }

                # if ascii not equal to 8 or delete condition equals 0
                else{

                    # store ascii value
                    push (@new, $_);
                }
            }

            # convert ascii back to characters and reverse back to original order
            $$_ = pack("C*", reverse(@new));
        }
    }
}

1;

__END__

=head1 NAME

Clean::Backspace - removes hidden backspaces and their corresponding deleted characters in strings

=head1 SYNOPSIS

  use Clean::Backspace;
  my $clean = Clean::Backspace->new();
  $clean->backspace(\@list_of_string_refs);

=head1 DESCRIPTION

This module removes "hidden" backspaces and their corresponding deleted characters from strings.
Some terminals generate the backspace control character ^H when backspacing. This is due to how
that particular terminal is configured. When terminals are configured to generate ^H instead of
ascii del the ^H character as well as the deleted character are retained in the string. If the
terminal is configured in this manner and the backspace is used the string may appear to be normal.

An example string on such a terminal could be the string 'test'. Let's say it was typed like this:
ted<backspace>st

When you look at the string it appears as 'test'. There are various mechanisms to detect the
hidden characters and the string is actually 'ted^Hst'. This can cause problems in various IT
infrastructures because all characters in the string will be interpreted. One example could be
with an Oracle database. The strings that are typed with backspaces might look normal in your
terminal but when you look at Oracle database table fields the unwanted characters might be visible.

=head1 METHODS

  There is just one method:  backspace().
  The method requires a list(s) reference(s) of string references.
  Ex: use Clean::Backspace;
      my $clean = Clean::Backspace->new();
      my $str1  = 'string1';
      my $str2  = 'string2';
      my @list  = (\$str1, \$str2);
      $clean->backspace(\@list);

  Since the references are processed there are no return values.

=head1 AUTHOR

Bruce Burch <bcb12001@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Bruce Burch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
