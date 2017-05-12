package testlib::StatusHTML;
use strict;
use warnings;
use Carp;
use testlib::HTTP;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        status_node => undef,
        raw_html => undef,
    }, $class;
    if(defined $args{node}) {
        $self->{status_node} = $args{node};
    }elsif(defined $args{html}) {
        $self->_set_node_from_html($args{html});
        $self->{raw_html} = $args{html};
    }else {
        croak "node or html param is mandatory";
    }
    return $self;
}

sub new_multiple {
    my ($class, $html) = @_;
    my @status_nodes = _get_status_nodes_from_html($html);
    return map { $class->new(node => $_) } @status_nodes;
}

sub _get_status_nodes_from_html {
    my ($html) = @_;
    my $root = testlib::HTTP->parse_html($html);
    return $root->findnodes('//*[@class="bb-status"]');
}

sub _set_node_from_html {
    my ($self, $html) = @_;
    my @status_nodes = _get_status_nodes_from_html($html);
    croak("No status element in HTML") if @status_nodes == 0;
    croak("There are multiple status elements in HTML") if @status_nodes > 1;
    $self->{status_node} = $status_nodes[0];
}

sub raw_html {
    my ($self) = @_;
    return $self->{raw_html};
}

sub level {
    my ($self) = @_;
    return $self->{status_node}->attr("data-bb-status-level");
}

sub get_member_elem {
    my ($self, $class_name) = @_;
    my @nodes = $self->{status_node}->findnodes(qq{.//*[\@class="$class_name"]});
    if(@nodes != 1) {
        croak(sprintf("There are %d elements for class %s", int(@nodes), $class_name))
    }
    my @contents = $nodes[0]->content_list;
    return join("", map {ref($_) ? $_->as_HTML(undef, undef, {}) : $_} @contents);
}

foreach my $getter_method (qw(id username created_at text)) {
    no strict "refs";
    my $property_name = $getter_method;
    $property_name =~ s/_/-/g;
    *{$getter_method} = sub {
        my ($self) = @_;
        return $self->get_member_elem("bb-status-$property_name");
    };
}

1;

