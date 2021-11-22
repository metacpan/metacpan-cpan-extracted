package App::ansiexpand;
our $VERSION = "0.9901";

use 5.014;
use warnings;

use open IO => 'utf8', ':std';
use Encode;
use Pod::Usage;
use Data::Dumper;
use Text::ANSI::Tabs qw(ansi_expand ansi_unexpand);

our $DEFAULT_UNEXPAND;

use Getopt::EX::Hashed 1.03 'has'; {

    has unexpand  => ' u  !   ' , default => $DEFAULT_UNEXPAND;
    has ambiguous => '    =s  ' , any => [ qw(wide narrow) ];
    has tabstop   => ' t  =i  ' , min => 1;
    has tabhead   => '    =s  ' ;
    has tabspace  => '    =s  ' ;
    has tabstyle  => ' ts =s  ' ;
    has help      => ' h      ' ;
    has version   => ' v       ' ;

    has '+tabstop' => sub {
	$Text::ANSI::Tabs::tabstop = $_[1];
    };

    has [ qw(+tabhead +tabspace +tabstyle) ] => sub {
	Text::ANSI::Tabs->configure("$_[0]" => $_[1]);
    };

    has '+help' => sub {
	pod2usage
	    -verbose  => 99,
	    -sections => [ qw(SYNOPSIS VERSION) ];
    };

    has '+version' => sub {
	print "Version: $VERSION\n";
	exit;
    };

} no Getopt::EX::Hashed;

sub run {
    my $app = shift;
    local @ARGV = map { utf8::is_utf8($_) ? $_ : decode('utf8', $_)  } @_;

    use Getopt::EX::Long qw(:DEFAULT ExConfigure Configure);
    ExConfigure BASECLASS => [ __PACKAGE__, 'Getopt::EX' ];
    Configure "bundling";
    $app->getopt || pod2usage();

    my $action = $app->{unexpand} ? \&ansi_unexpand : \&ansi_expand;

    while (<>) {
	print $action->($_);
    }

    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

ansiexpand, ansiunexpand - ANSI sequence aware tab expand/unexpand command

=head1 VERSION

Version 0.9901

=head1 DESCRIPTION

Documentation is included in the script file.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

