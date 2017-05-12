package App::BCSSH::Inline;
use strictures 1;
use Moo ();
use Moo::Role ();
use Module::Runtime qw(module_notional_filename);
use Import::Into;

use base 'Exporter';
our @EXPORT = qw(make_handler);

sub import {
    my $class = $_[0];
    my ($target, $file) = caller;
    my $filename = module_notional_filename($target);
    $INC{$filename} ||= $file;

    $class->export_to_level(1, @_);
}

sub make_handler (&) {
    my $handler = shift;
    my ($class, $file) = caller;
    my $handler_name = $class->handler;
    my $role = 'App::BCSSH::Handler';
    my $handler_class = "${role}::${handler_name}";
    $INC{module_notional_filename($handler_class)} ||= $file;
    Moo->import::into($handler_class);
    Moo::Role->apply_roles_to_package($handler_class, $role);
    no strict 'refs';
    *{"${handler_class}::handle"} = $handler;
    return 1;
}

1;
