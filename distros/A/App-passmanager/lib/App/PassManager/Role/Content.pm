package App::PassManager::Role::Content;
{
  $App::PassManager::Role::Content::VERSION = '1.113580';
}
use Moose::Role;

has '_data' => (
    is => 'rw',
    isa => 'HashRef',
    accessor => 'data',
);

has '_category' => (
    is => 'rw',
    isa => 'Str',
    accessor => 'category',
);

has '_category_id' => (
    is => 'rw',
    isa => 'Int',
    accessor => 'category_id',
);

has '_service' => (
    is => 'rw',
    isa => 'Str',
    accessor => 'service',
);

has '_service_id' => (
    is => 'rw',
    isa => 'Int',
    accessor => 'service_id',
);

has '_entry' => (
    is => 'rw',
    isa => 'Str',
    accessor => 'entry',
);

sub category_list {
    my $self = shift;

    # clear service and entry lists
    $self->win->{browse}->getobj('service')->values([]);
    $self->win->{browse}->getobj('entry')->values([]);

    # update help text
    $self->win->{status}->getobj('status')->text(
        "Quit: Ctrl-Q | Abandon Changes: Ctrl-R | Add: A | Edit: E | Delete: D");

    # populate category list and set focus
    my $category = $self->win->{browse}->getobj('category');
    $category->values([sort keys %{$self->data->{category} || {}}]);
    $category->{'-ypos'} = $self->category_id if $self->category_id; # XXX private?
    $category->focus;
}

sub service_show {
    my $self = shift;

    # grab selected category
    my $cat = $self->win->{browse}->getobj('category')->get_active_value
        or return;
    return unless exists $self->data->{category}->{$cat};

    # populate service list and redraw
    my $service = $self->win->{browse}->getobj('service');
    $service->values([sort keys %{
        $self->data->{category}->{$cat}->{service} || {}
    }]);
    $service->draw;
}

sub service_list {
    my $self = shift;

    # grab selected category
    my $category = $self->win->{browse}->getobj('category');
    my $item = $category->get or return;
    $self->category($item);
    # save category position so we can set it on return
    $self->category_id($category->id);

    # clear entry list (for backtrack from entry)
    $self->win->{browse}->getobj('entry')->values([]);

    # update help text
    $self->win->{status}->getobj('status')->text(
        "Quit: Ctrl-Q | Abandon Changes: Ctrl-R | Add: A | Edit: E | Delete: D");

    my @values = sort keys %{
        $self->data->{category}->{$self->category}->{service} || {} };

    if (scalar @values) {
        # populate service list and set focus
        my $service = $self->win->{browse}->getobj('service');
        $service->values([@values]);
        $service->{'-ypos'} = $self->service_id if $self->service_id; # XXX private?
        $service->focus;
    }
    else {
        # need a new service, first
        $self->add('Service', $self->data->{category}->{$item});
    }
}

sub entry_show {
    my $self = shift;

    return if $self->win->{browse}->getfocusobj
        eq $self->win->{browse}->getobj('category');

    # grab selected category
    my $svc = $self->win->{browse}->getobj('service')->get_active_value
        or return;
    return unless $self->category
        and exists $self->data->{category}->{$self->category}
        and exists $self->data->{category}->{$self->category}->{service}->{$svc};

    # populate entry list and redraw
    my $entry = $self->win->{browse}->getobj('entry');
    $entry->values([sort keys %{
        $self->data->{category}->{$self->category}->{service}->{$svc}->{entry}
            || {}
    }]);
    $entry->draw;
}

sub entry_list {
    my $self = shift;

    # grab selected service
    my $service = $self->win->{browse}->getobj('service');
    my $item = $service->get or return;
    $self->service($item);
    # save service position so we can set it on return
    $self->service_id($service->id);

    # update help text
    $self->win->{status}->getobj('status')->text(
        "Quit: Ctrl-Q | Abandon Changes: Ctrl-R | Add: A | Edit: E | Delete: D");

    my @values = sort keys %{
        $self->data->{category}->{$self->category}
            ->{service}->{$self->service}->{entry} || {} };

    if (scalar @values) {
        # populate entry list and set focus
        my $entry = $self->win->{browse}->getobj('entry');
        $entry->values([@values]);
        $entry->focus;
    }
    else {
        # need a new entry, first
        $self->add('Entry',
            $self->data->{category}->{$self->category}->{service}->{$item});
    }
}

sub display_entry {
    my $self = shift;

    # grab selected entry
    my $item = $self->win->{browse}->getobj('entry')->get
        or return;
    $self->entry($item);

    # throw up a dialog box with the fields
    my $loc = $self->data->{category}->{$self->category}
            ->{service}->{$self->service}->{entry}
            ->{$self->entry};
    $self->ui->dialog(
        "Username: ". ($loc->{username} || '') ."\n".
        "Password: ". ($loc->{password} || '') ."\n".
        "Comment:  ". ($loc->{description} || '')
    );
}

sub delete {
    my ($self, $name, $loc, $key) = @_;

    my $type = lc $name;
    return unless $key and exists $loc->{$type}->{$key};

    my $yes = $self->ui->dialog(
        -message => qq{Really delete $name "$key"?},
        -buttons => ['yes', 'no'],
        -values  => [1, 0],
        -title   => 'Confirm',
    );

    if ($yes) {
        delete $loc->{$type}->{$key};
        my $list = "${type}_list";
        $self->$list;
    }
}

sub ask {
    my ($self, $what, $val) = @_;

    my $ret = $self->ui->question(
        -title   => "New Entry",
        -question => "Entry $what:",
        ($val ? (-answer => $val) : ()),
    );
    return $ret;
}

sub edit {
    my ($self, $name, $loc, $key) = @_;

    my $type = lc $name;
    return unless $key and exists $loc->{$type}->{$key};
    my $newkey;

    if ($type eq 'entry') {
        my ($title, $user, $pass, $comment) = (
            $self->ask('Name', $key),
            $self->ask('Username', $loc->{$type}->{$key}->{username}),
            $self->ask('Password', $loc->{$type}->{$key}->{password}),
            $self->ask('Comment', $loc->{$type}->{$key}->{description}),
        );
        return unless $title and ($user or $pass);
        $newkey = $title;
        $loc->{$type}->{$newkey} = {
            username => $user,
            password => $pass,
            description => $comment,
        };
    }
    else {
        $newkey = $self->ui->question(
            -title   => "Edit",
            -question => "$name Name:",
            -answer => $key,
        );
        return unless $newkey;
        $loc->{$type}->{$newkey} = $loc->{$type}->{$key};
    }

    delete $loc->{$type}->{$key}
        if $key ne $newkey;

    my $list = "${type}_list";
    $self->$list;
}

sub add {
    my ($self, $name, $loc) = @_;

    my $type = lc $name;
    $loc->{$type} ||= {};
    my ($key, $val);

    if ($type eq 'entry') {
        my $title = $self->ask('Name');
        return unless $title;
        my ($user, $pass, $comment) = (
            $self->ask('Username'),
            $self->ask('Password'),
            $self->ask('Comment'),
        );
        return unless ($user or $pass);
        $key = $title;
        $val = {
            username => $user,
            password => $pass,
            description => $comment,
        };
    }
    else {
        $key = $self->ui->question(
            -title   => "New",
            -question => "$name Name:",
        );
        return unless $key;
        $val = {};
    }

    $loc->{$type}->{$key} = $val;

    my $list = "${type}_list";
    $self->$list;
}

1;
