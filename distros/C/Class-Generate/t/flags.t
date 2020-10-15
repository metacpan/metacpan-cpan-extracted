#! /usr/local/bin/perl

use lib qw(./t);
use warnings;
use strict;
use Test_Framework;

# Test some flags:
#   --  excluded methods.
#   --  use packages.
#   --  virtual classes.

use Class::Generate qw(&class);

use vars qw($o @mems);

@mems = ( 's' => "\$", a => '@', h => '%' );

Test
{
    class No_Undef   => {@mems}, -exclude => 'undef';
    class Some_Undef => {@mems}, -exclude => '^undef_[ah]';
    class
        No_a     => { @mems, '&func' => '@a = @_; return $#a;' },
        -exclude => '\<a\>';
    class No_h_keys => {@mems}, -exclude => 'h_keys';

    # The following has no effect, but it is a valid regexp.
    class Regexp_Quote_Check => {@mems}, -exclude => '\'';
    1;
};

Test_Failure { ( new No_Undef )->undef_s };
Test_Failure { ( new No_Undef )->undef_a };
Test_Failure { ( new No_Undef )->undef_h };

Test { ( new Some_Undef )->undef_s; 1 };
Test_Failure { ( new No_Undef )->undef_a };
Test_Failure { ( new No_Undef )->undef_h };

Test_Failure { ( new No_a )->undef_a; };

Test { $o = new No_a; $o->func( 1, 2, 3 ) == 2 };

Test { my @a = ( new No_a h => { v => 1, w => 2 } )->h_values; $#a == 1 };
Test_Failure { ( new No_h_keys h => { v => 1, w => 2 } )->h_keys };

Test
{
    class User1 => {
        word => {
            type => "\$",
            post => '$soundx = soundex $word if $word;'
        },
        soundx => "\$",
        text   => { type => "\$", post => '$text = expand $text if $text;' },
        new    => {
            post => 'use vars qw($soundex_nocode);
                          $soundex_nocode = "Z000";
                          $soundx = soundex $word if $word;
                          $text = expand $text if $text;'
        }
        },
        '-use' => 'Text::Soundex Text::Tabs';
    class User2 => {    # Same as User1, except array reference
        word => {
            type => "\$",    # form specifies the packages used.
            post => '$soundx = soundex $word if $word;'
        },
        soundx => "\$",
        text   => { type => "\$", post => '$text = expand $text if $text;' },
        new    => {
            post => 'use vars qw($soundex_nocode);
                          $soundex_nocode = "Z000";
                          $soundx = soundex $word if $word;
                          $text = expand $text if $text;'
        }
        },
        '-use' => [ 'Text::Soundex', 'Text::Tabs' ];
};

Test { class Virtual => {@mems}, -virtual => 1; 1 };
Test_Failure { new Virtual };

Test
{    # Current directory must be writeable.
    my $comment = 'This is a comment';
    my $file    = 'Has_Comment.pm';
    class
        Has_Comment => {@mems},
        -comment    => $comment,
        -options    => { save => 1 };
    local $/ = undef;
    open HC, "<$file" or die "Can't open saved Perl module";
    my $module = <HC>;
    close HC;
    unlink $file;
    $module =~ m/$comment/
};

Report_Results;
