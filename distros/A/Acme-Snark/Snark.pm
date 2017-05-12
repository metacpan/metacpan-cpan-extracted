package Acme::Snark;

use strict;
use vars qw($VERSION);
$VERSION = '0.04';

my %stash;

sub TIESCALAR {
    my $foo;
    return bless \$foo, 'Acme::Snark';
}

sub FETCH {
    my $t_obj = {value => ${$_[0]} };
    bless($t_obj, 'Acme::Snark::HONK');
    return $t_obj;
}

sub STORE {
    if (defined($_[1]) && !$_[1]) {
	$stash{'>' . $_[1] . '<'}++;
    }
    elsif (!defined($_[1])) {
	$stash{'<>'}++;
    }
    ${$_[0]} = $_[1];
}

package Acme::Snark::HONK;

use overload
    q{bool} => sub {
	if (defined($_[0]->{value}) && !$_[0]->{value}) {
	    
	    return $stash{'>'.$_[0]->{value}.'<'} > 2 ? 1 : $_[0]->{value};
	}
	elsif (!defined($_[0]->{value})) {
	    return $stash{'<>'} > 2 ? 1 : 0;
	}
	else {
	    return $_[0]->{value};
	}
    },
    '+' => sub {my @a=&rev; $a[0] + $a[1]},
    '-' => sub {my @a=&rev; $a[0] - $a[1]},
    '/' => sub {my @a=&rev; $a[0] / $a[1]},
    '*' => sub {my @a=&rev; $a[0] * $a[1]},
    '**' => sub {my @a=&rev; $a[0] **$a[1]},
    '.' => sub {my @a=&rev; $a[0] . $a[1]},
    '%' => sub {my @a=&rev; $a[0] % $a[1]},
    'x' => sub {my @a=&rev; $a[0] x $a[1]},
    '&' => sub {my @a=&rev; $a[0] & $a[1]},
    '^' => sub {my @a=&rev; $a[0] ^ $a[1]},
    '|' => sub {my @a=&rev; $a[0] | $a[1]},
    '<=>' => sub {my @a=&rev; $a[0]<=>$a[1]},
    'cmp' => sub {my @a=&rev; $a[0]cmp$a[1]},
    q{+0} => sub {$_[0]->{value}},
    q{""} => sub {$_[0]->{value}},
    ;

sub rev {
    if ($_[2]) {
	return ($_[1], $_[0]->{value});
    }
    else {
	return ($_[0]->{value}, $_[1]);
    }
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!
# And if I don't?  Who ya gonna tell?

=head1 NAME

Acme::Snark - What I tell you three times is true

=head1 SYNOPSIS

  use Acme::Snark;
  tie $foo, Acme::Snark;

  $foo = 0;
  $foo = 0;
  $foo = 0;

  print "True\n" if $foo;

=head1 DESCRIPTION

 Just the place for a Snark!  I have said it twice:
      That alone should encourage the crew.
 Just the place for a Snark!  I have said it thrice:
      What I tell you three times is true.

=head1 BUGS

Fetch gets called far, far too many times, which is confusing.

=head1 AUTHOR

Alex Gough (alex@earth.li) - Go on, I feel lonely...

Thanks to mstevens for getting the joke.

=head1 SEE ALSO

perl(1). Psychiatrist(8).
_The Hunting of the Snark_
_Stand on Zanzibar_

=head1 COPYRIGHT

This module is Copyright (c) Alex Gough, 2001.

=head1 LICENSE

This is free software, you may use and redistribute this code under the
same terms as perl itself.

=cut
