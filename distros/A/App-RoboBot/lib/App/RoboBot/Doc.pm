package App::RoboBot::Doc;
$App::RoboBot::Doc::VERSION = '4.004';
use v5.20;

use namespace::autoclean;
use Moose;

use Pod::Simple::SimpleTree;

has 'bot' => (
    is       => 'ro',
    isa      => 'App::RoboBot',
    required => 1,
);

has 'parser' => (
    is      => 'ro',
    isa     => 'Pod::Simple::SimpleTree',
    default => sub { my $p = Pod::Simple::SimpleTree->new; $p->merge_text(1); return $p },
);

has 'pod_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'module_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'function_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub list_modules {
    my ($self) = @_;

    return sort map { $_->ns } @{$self->bot->plugins};
}

sub list_module_functions {
    my ($self, $module) = @_;

    return unless defined $module;

    my $plugin = (grep { $_->ns eq $module } @{$self->bot->plugins})[0];
    return unless defined $plugin;

    return sort keys %{$plugin->commands};
}

sub module {
    my ($self, $module) = @_;

    return unless defined $module;
    return $self->module_cache->{$module} if exists $self->module_cache->{$module};

    my $pm_file = $self->_find_pm($module);
    my $pod = $self->_extract_pod($pm_file);

    return unless exists $pod->{$module};

    $self->module_cache->{$module} = $pod->{$module};
    return $pod->{$module};
}

sub function {
    my ($self, $module, $function) = @_;

    return unless defined $function;

    if (!defined $module) {
        my @modules = map { $_->ns } grep { exists $_->commands->{$function} } @{$self->bot->plugins};

        return if @modules == 0;
        return \@modules if @modules > 1;

        $module = $modules[0];
    }

    my $ns_function = "$module/$function";
    return $self->function_cache->{$ns_function} if exists $self->function_cache->{$ns_function};

    my $module_doc = $self->module($module);

    $self->function_cache->{$ns_function} = $module_doc->{'methods'}{$function};
    return $module_doc->{'methods'}{$function};
}

sub _extract_pod {
    my ($self, $pm_file) = @_;

    return unless defined $pm_file;
    return $self->pod_cache->{$pm_file} if exists $self->pod_cache->{$pm_file};
    return unless -f $pm_file && -r _;

    my %doc;
    my ($plugin, $method, $section);

    foreach my $block (@{ $self->parser->filter($pm_file)->root }) {
        next unless ref($block) eq 'ARRAY';

        if ($block->[0] eq 'head1') {
            $plugin = $block->[2];
            undef $method;
            undef $section;

            $doc{$plugin} = {
                description => [],
                methods     => {},
            } unless exists $doc{$plugin};
        } elsif ($block->[0] eq 'head2') {
            $method = $block->[2];
            undef $section;

            $doc{$plugin}{'methods'}{$method} = {
                summary => [],
            } unless exists $doc{$plugin}{'methods'}{$method};
        } elsif ($block->[0] eq 'head3') {
            $section = lc($block->[2]);
            $section =~ s{[^a-z0-9]+}{-}g;
            $section =~ s{(^-|-$)}{}g;
        } elsif ($block->[0] eq 'Para' || $block->[0] eq 'Verbatim') {
            my $text = join('', @$block[2..$#$block]);

            if (defined $section) {
                push(@{$doc{$plugin}{'methods'}{$method}{$section}}, $text);
            } elsif (defined $method) {
                push(@{$doc{$plugin}{'methods'}{$method}{'summary'}}, $text);
            } elsif (defined $plugin) {
                push(@{$doc{$plugin}{'description'}}, $text);
            }
        }
    }

    $self->pod_cache->{$pm_file} = \%doc;
    return $self->pod_cache->{$pm_file};
}

sub _find_pm {
    my ($self, $module) = @_;

    return unless defined $module;

    my $plugin = (grep { $_->ns eq $module } @{$self->bot->plugins})[0];
    return unless defined $plugin;

    my $plugin_class = ref($plugin) . '.pm';
    $plugin_class =~ s{::}{/}g;

    foreach my $lib (keys %INC) {
        return $INC{$lib} if $lib =~ m{$plugin_class$};
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;
