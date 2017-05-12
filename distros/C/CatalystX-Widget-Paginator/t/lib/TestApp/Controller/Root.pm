package TestApp::Controller::Root;

use Moose;

BEGIN { extends 'Catalyst::Controller' }


__PACKAGE__->config( namespace => '' );


sub default :Private {
    my ( $self, $c ) = @_;

    $c->res->body('not found');
    $c->res->status(404);
}

sub index :Path :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body('ok');
}

sub user :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->model('Simple::User')->search(1)->first->name );
}

sub defaults :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
	));
}

sub delim0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		delim => ' --- ',
	));
}

sub delim1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		delim => undef,
	));
}

sub edges0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		edges => undef,
	));
}

sub edges1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		edges => ['-','+'],
	));
}

sub invalid0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		page  => 333,
	));
}

sub invalid1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		invalid => 'last',
		page    => 333,
	));
}

sub invalid2 :Local :Args(0) {
	my ( $self, $c ) = @_;

	eval {
		$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
			invalid => 'raise',
			page    => 333,
		));
	};
	$c->res->body('catched')
		if $@ && $@ =~ /PAGE_OUT_OF_RANGE/;
}

sub invalid3 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		invalid => sub { $c->detach('/index') },
		page    => 333,
	));
}

sub invalid4 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		invalid => 'first',
		page    => 333,
	));
}

sub link0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		link => sub { shift() ** 2 },
	));
}

sub main0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		main => 5,
	));
}

sub namespace0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('+CatalystX::Widget::Paginator', rs => 'Simple::User',
	));
}

sub objects0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	my $w = $c->widget('Paginator', rs => 'Simple::User',
		page => 5,
	);

	$c->res->body( $w . '<br>' . join ':', map { $_->name } $w->objects->all );
}

sub page0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		page => 5,
	));
}

sub page1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator',
		rs => $c->model('Simple::User')->search_rs( undef, { page => 3 } ),
	));
}

sub page2 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator',
		rs   => $c->model('Simple::User')->search_rs( undef, { page => 3 } ),
		page => 5,
	));
}

sub page_arg0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
	));
}

sub page_arg1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		page => 5,
	));
}

sub page_arg2 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator',
		rs => $c->model('Simple::User')->search_rs( undef, { page => 5 } ),
	));
}

sub page_arg3 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		page_arg => 'page',
	));
}

sub page_auto0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		page_auto => 0,
	));
}

sub prefix0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		prefix => 'xxx',
	));
}

sub prefix1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		prefix => undef,
	));
}

sub prefix2 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		prefix => sub { 'Prefix!' . ( shift->total ** 2 ) },
	));
}

sub rows0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		rows => 5,
	));
}

sub rows1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator',
		rs => $c->model('Simple::User')->search_rs( undef, { rows => 3 } ),
	));
}

sub rows2 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator',
		rs   => $c->model('Simple::User')->search_rs( undef, { rows => 3 } ),
		rows => 5,
	));
}

sub side0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		side => 5,
	));
}

sub side1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		side => 0,
	));
}

sub style0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		style => 'xxx',
	));
}

sub style1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		style_prefix => 'xxx',
	));
}

sub subclass0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('~Pager', rs => 'Simple::User' ));
}

sub subclass1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('~SimplePager', rs => 'Simple::User' ));
}

sub suffix0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		suffix => 'xxx',
	));
}

sub suffix1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		suffix => undef,
	));
}

sub suffix2 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		suffix => sub { 'Suffix!' . ( shift->total ** 2 ) },
	));
}

sub text0 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		text => 't:%s',
	));
}

sub text1 :Local :Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->widget('Paginator', rs => 'Simple::User',
		text => sub { 'text:' . shift() },
	));
}

__PACKAGE__->meta->make_immutable;

1;

