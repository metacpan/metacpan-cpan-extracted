package Growl::Any;
our ( $SUB_NEW_ARGS, $SUB_NOTIFY_ARGS );

sub new {
    my $class = shift;
    die unless $class eq __PACKAGE__;
    $SUB_NEW_ARGS = {@_};
    bless {}, $class;
}

sub notify {
    my $self = shift;
    $SUB_NOTIFY_ARGS = [@_];
}

1;
