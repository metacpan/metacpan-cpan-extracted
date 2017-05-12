package CatalystX::Crudite::Controller::Resource;
use Moose;
use namespace::autoclean;
use CatalystX::Crudite::Util qw(merge_configs);
BEGIN { extends 'CatalystX::Resource::Controller::Resource' }
sub _trait_namespace { 'CatalystX::Resource::TraitFor::Controller::Resource' }

sub config_resource_controller {
    my ($class, %args) = @_;
    my $app_name       = $class =~ s/::.*//r;
    my $package_to_key = sub {
        my $package = shift;
        my $key;

        # e.g., package 'ContentType' => key 'content_type'
        $key = $package =~ s/[a-z]\K([A-Z])/_\L$1/gr;
        lc $key;
    };
    my $singular_package = delete $args{singular_package}
      // ($class =~ s/.*:://r);
    my $singular_key = delete $args{singular_key}
      // $package_to_key->($singular_package);
    my $plural_key = delete $args{plural_key} // $singular_key . 's';
    my $parent_resource;
    if ($parent_resource = delete $args{parent_resource}) {
        $parent_resource = $package_to_key->($parent_resource);
    }
    my $traits = $args{traits} // [qw(Form Create Edit Delete List Show)];
    my $has_delete_trait = grep { $_ eq 'Delete' } @$traits;
    my %config = (
        resultset_key => $plural_key,
        resource_key  => $singular_key,
        form_class    => "${app_name}::Form::${singular_package}",

        # Catalyst::View::TT by default uses the lc() of the
        # controller name as the template directory of that
        # contoller, so we need to do that as well instead of using
        # $singular_key. So, for example, MyApp::Controller::FooBar
        # will look for templates in foobar/.
        form_template => "\L$singular_package/edit.tt",
        model         => "DB::$singular_package",
        redirect_mode => 'list',
        traits        => $traits,
        (   $parent_resource
            ? ( parent_key       => $parent_resource,
                parents_accessor => $plural_key,
              )
            : ()
        ),
        actions => {
            base => {
                Does => [qw(NeedsLogin Code)],
                (   $parent_resource
                    ? (Chained => "/$parent_resource/base_with_id")
                    : ()
                ),
                PathPart => $plural_key,
                Code     => [ \&stash_form_attrs ],
            },
            ($has_delete_trait ? (delete => { Method => 'GET' }) : ()),
        },
    );
    my $merged_config = merge_configs(\%config, \%args);
    $class->config($merged_config);
}

sub stash_form_attrs {
    my $orig   = shift;
    my $action = shift;
    my ($controller, $c) = @_;
    $c->stash->{form_attrs_new} //= {};        # don't overwrite existing
    $c->stash->{form_attrs_new}{ctx} //= $c;
    $action->$orig(@_);
}
1;
