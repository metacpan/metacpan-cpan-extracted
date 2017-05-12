use CatalystX::Declare;
namespace TestApp;
role ::ActionRole::hasActionParams_AppNS {
    has [qw/p1 p2/] => (is=>'ro', lazy_build=>1);
    method _build_p1 {
        join ',', @{$self->attributes->{p1}};
    }
    method _build_p2 {
        join ',', @{$self->attributes->{p2}};
    }
}

