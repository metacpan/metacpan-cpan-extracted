use strict;
use warnings;
use ExtUtils::MakeMaker 6.58;
my $from = 'lib/DB/Pluggable.pm';
WriteMakefile(
    ABSTRACT_FROM      => $from,
    AUTHOR             => 'Marcel Gruenauer <marcel@cpan.org>',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.58' },
    LICENSE            => 'perl',
    NAME               => 'DB::Pluggable',
    PREREQ_PM          => {
        'Brickyard'               => '1.111750',
        'Brickyard::Accessor'     => '0',
        'Brickyard::Role::Plugin' => '0',
        'Data::Printer'           => '0',
        'Hook::LexWrap'           => '0',
        'Role::Basic'             => '0',
        'Test::Builder'           => '0'
    },
    VERSION_FROM => $from,
    test         => { TESTS => 't/*.t' }
);
