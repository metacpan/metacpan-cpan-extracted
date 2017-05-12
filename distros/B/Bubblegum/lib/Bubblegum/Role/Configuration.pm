package Bubblegum::Role::Configuration;

use 5.10.0;
use namespace::autoclean;

use strict;
use utf8::all;
use warnings;

use Import::Into;
use Moo::Role;

use Bubblegum::Namespace ();
use feature ();
use mro ();

use Class::Load 'load_class', 'try_load_class';
use parent 'autobox';

our $VERSION = '0.45'; # VERSION

requires 'import';

BEGIN {
    use Bubblegum::Object::Universal; # tisk tisk
    push @UNIVERSAL::ISA, 'Bubblegum::Object::Universal';
}

sub prerequisites {
    my ($class, $target) = @_;

    # autoload
    unless (my $ignore = ($target =~ /^Bubblegum::Object/)) {
        load_class 'Bubblegum::Object::Undef';
        load_class 'Bubblegum::Object::Array';
        load_class 'Bubblegum::Object::Code';
        load_class 'Bubblegum::Object::Float';
        load_class 'Bubblegum::Object::Hash';
        load_class 'Bubblegum::Object::Instance';
        load_class 'Bubblegum::Object::Integer';
        load_class 'Bubblegum::Object::Number';
        load_class 'Bubblegum::Object::Scalar';
        load_class 'Bubblegum::Object::String';
        load_class 'Bubblegum::Object::Universal';
    }

    # resolution
    mro::set_mro $target, 'c3';

    # ipc handler
    my $ipc = try_load_class 'IPC::System::Simple';

    # imports
    'strict'    ->import::into($target);
    'warnings'  ->import::into($target);
    'utf8::all' ->import::into($target);
    'autodie'   ->import::into($target, ':all') if $ipc;
    'autodie'   ->import::into($target, ':default') if !$ipc;
    'feature'   ->import::into($target, ':5.10');
    'English'   ->import::into($target, '-no_match_vars');

    # autoboxing
    no warnings 'once';
    $target->autobox::import(
        map { $_ => $$Bubblegum::Namespace::ExtendedTypes{$_} }
            keys %$Bubblegum::Namespace::DefaultTypes
    );
}

1;
