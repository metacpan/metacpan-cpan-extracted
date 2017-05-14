use utf8;
package Acme::ǝmɔA;

use strict;
use Encode;
use Text::UpsideDown;
use Filter::Simple;

# Use a known line for the header to tell us if the file has already been
# altered.
use constant "HEADER_TEXT" => "use utf8;use Acme::ǝmɔA;";
use constant "WIDTH" => 80;
use constant "HEADER" => " " x (WIDTH-length HEADER_TEXT) . HEADER_TEXT;

# Filter::Simple calls this, does all the hard work.
FILTER {
  my $file = (caller(1))[1];

  if(is_upside_down($file)) {
    my @r = reverse split /\n/, decode_utf8 $_;
    s/^\s*(.*)$/upside_down($1)/gem for @r;
    $_ = join "\n", @r;

  } else {
    turn_upside_down($file);
  }
};

sub is_upside_down {
  my($file) = @_;

  open my $fh, "<:encoding(UTF-8)", $file or die $!;

  local $_;
  while(<$fh>) {
    chomp;
    next if /^#/;
    return 1 if $_ eq HEADER;
  }
  return 0;
}

sub turn_upside_down {
  my($file) = @_;
  local $_;

  my $new_file = "$file.new.$$";

  open my $in, "<:encoding(UTF-8)", $file or die $!;
  open my $out, ">:encoding(UTF-8)", $new_file
    or die "Unable to write to file to turn $file upside down: $!";

  # XXX: The decode_utf8 required here is because perl stashes are not actually
  # UTF-8 aware (see perltodo).
  my $package = quotemeta decode_utf8 __PACKAGE__;
  while(<$in>) {
    if(/use\s+$package/) {
      print $out HEADER, "\n";
      last;
    }
    print $out $_;
  }

  for(reverse <$in>) {
    s/\r?\n$//;
    my $u = upside_down($_);
    $u = " " x (WIDTH - length $u) . $u if length $u < WIDTH;
    print $out $u, "\n";
  }

  # XXX: copy perms
  rename $new_file, $file;
}

"með blóðnasir"

__END__

=encoding utf-8

=head1 NAME

Acme::ǝmɔA - Turn your perl upside down

=head1 SYNOPSIS

  use utf8; use Acme::ǝmɔA;

  ɹǝpun uʍop ʍou ǝɹ,no⅄ #

=head1 DESCRIPTION

Turns your perl code upside down.

This is yet another Acme module that does something amusing yet useless to your
code. I'm afraid I couldn't resist.

=head1 BUGS

The bug density is so high this module has ceased existing and is now held
together by the bugs that are crawling through it.

=over 4

=item *

Source filter usage means __DATA__ and probably other things don't work.

=item *

Assumes UTF-8 in places it probably shouldn't.

=back

=head1 SEE ALSO

L<Acme::Bleach> which started it all, L<Acme::Palindrome>, L<Acme::emcA>
and L<Acme::Ünicöde> which appears to have pioneered Unicode package names.

=head1 LICENCE

There is no warranty for this code. You really do use it at your own risk.

      DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                   Version 2, December 2004

  Copyright (C) 2004 Sam Hocevar
   14 rue de Plaisance, 75014 Paris, France
  Everyone is permitted to copy and distribute verbatim or modified
  copies of this license document, and changing it is allowed as long
  as the name is changed.

           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. You just DO WHAT THE FUCK YOU WANT TO.

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>
