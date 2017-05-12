package Acme::Module::Authors;

use strict;
require 5.006;
our $VERSION = 0.01;

my @modules;

# flag if we're in END { }
my $in_end = 0;

sub import {
    shift;
    unshift @INC, sub {
	my($self, $file) = @_;
	return if $in_end;
	push @modules, file2mod($file);
	return;
    };
}

sub file2mod {
    local $_ = shift;
    s/\.pm$//;
    s!/!::!g;
    return $_;
}

sub author_for {
    my $name = shift;
    my $module = CPAN::Shell->expand(Module => $name);

    # ignore perl-core pragmas like overload, constant, strict ...
    return if !$module or
	($name =~ /^[a-z]/ and $module->cpan_file =~ m!perl-[\d\.]+\.tar\.gz$!);

    my $author = CPAN::Shell->expand(Author => $module->userid);
    return $author->name;
}

END {
    $in_end = 1;
    require CPAN;
    local $CPAN::Frontend = 'Acme::Module::Authors::CPAN';
    my %authors;
    for my $module (@modules) {
	my $author = author_for($module) or next;
	push @{$authors{$author}}, $module;
    }
    local $" = ', ';
    print "This program runs thanks to:\n";
    print "  $_ for @{$authors{$_}}\n"
	for sort { @{$authors{$b}} <=> @{$authors{$a}} } keys %authors;
}

@Acme::Module::Authors::CPAN::ISA = qw(CPAN::Shell);
sub Acme::Module::Authors::CPAN::myprint { }

1;
__END__

=head1 NAME

Acme::Module::Authors - Thank you CPAN authors

=head1 SYNOPSIS

  use Acme::Module::Authors;
  # in END phase it'll print out author names of modules used

=head1 DESCRIPTION

Acme::Module::Authors allows you to realize how your programs benefit
from CPAN modules. Then you can thank authors of these modules.

=head1 NOTE

This module uses CPAN.pm to get module author name, which is
slow. Parsing POD's AUTHOR section will makei it more efficient. (But
it's hard because author names are in free form)

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CPAN>

=cut
