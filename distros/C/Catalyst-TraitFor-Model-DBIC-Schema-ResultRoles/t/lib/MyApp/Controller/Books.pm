package MyApp::Controller::Books;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub authors_by_id :Local :Args(1){
	my ($self, $c, $id) = @_;
	die "no id" unless $id;
	my $book = $c->model("DB::Book")->find($id);
	die "no book with id $id" unless $book;
    	$c->response->body("authors for book id $id: " . join ", ", map {$_->name} $book->authors);
}

sub author_count :Local :Args(1){
	my ($self, $c, $id) = @_;
	die "no id" unless $id;
	my $book = $c->model("DB::Book")->find($id);
	die "no book with id $id" unless $book;
	$c->response->body("Book with id $id has " . $book->count . " authors");
}

sub related_books :Local :Args(1){
	my ($self, $c, $id) = @_;
	die "no id" unless $id;
	my $book = $c->model("DB::Book")->find($id);
	die "no book with id $id" unless $book;
	my %related;
	foreach my $author ($book->authors){
		foreach my $authors_book ($author->books){
			foreach ($authors_book->authors){
				$related{$authors_book->title}{$_->name} = 1 if not $authors_book->title eq $book->title;
		}
		}
	}
	$c->response->body("related books for id $id: ". join(", ", map{ $_ .' ('. join (", ", keys %{$related{$_}})  .')'} keys %related));
}
__PACKAGE__->meta->make_immutable;

