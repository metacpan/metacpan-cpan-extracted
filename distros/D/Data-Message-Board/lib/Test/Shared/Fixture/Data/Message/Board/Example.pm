package Test::Shared::Fixture::Data::Message::Board::Example;

use base qw(Data::Message::Board);
use strict;
use warnings;

use Data::Message::Board::Comment;
use Data::Person;
use DateTime;

our $VERSION = 0.06;

sub new {
	my $class = shift;

	my @params = (
		'author' => Data::Person->new(
			'name' => 'John Wick',
		),
		'comments' => [
			Data::Message::Board::Comment->new(
				'author' => Data::Person->new(
					'name' => 'Gregor Herrmann',
				),
				'date' => DateTime->new(
					'day' => 25,
					'month' => 5,
					'year' => 2024,
					'hour' => 17,
					'minute' => 53,
					'second' => 27,
				),
				'id' => 1,
				'message' => 'apt-get update; apt-get install perl;',
			),
			Data::Message::Board::Comment->new(
				'author' => Data::Person->new(
					'name' => 'Emmanuel Seyman',
				),
				'date' => DateTime->new(
					'day' => 25,
					'month' => 5,
					'year' => 2024,
					'hour' => 17,
					'minute' => 53,
					'second' => 37,
				),
				'id' => 2,
				'message' => 'dnf update; dnf install perl-intepreter;',
			),
		],
		'date' => DateTime->new(
			'day' => 25,
			'month' => 5,
			'year' => 2024,
			'hour' => 17,
			'minute' => 53,
			'second' => 20,
		),
		'id' => 7,
		'message' => 'How to install Perl?',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Data::Message::Board::Example - Data fixture via Data::Message::Board.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Data::Message::Board::Example;

 my $obj = Test::Shared::Fixture::Data::Message::Board::Example->new(%params);
 my $author = $obj->author;
 my $comments_ar = $obj->comments;
 my $date = $obj->date;
 my $id = $obj->id;
 my $message = $obj->message;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Data::Message::Board::Example->new(%params);

Constructor.

Returns instance of object.

=head2 C<author>

 my $author = $obj->author;

Get author instance.

Returns L<Data::Person> instance.

=head2 C<comments>

 my $comments_ar = $obj->comments;

Get message board comments.

Returns reference to array with L<Data::Message::Board::Comment> instances.

=head2 C<date>

 my $date = $obj->date;

Get datetime of comment.

Returns L<DateTime> instance.

=head2 C<id>

 my $id = $obj->id;

Get comment id.

Returns natural number.

=head2 C<>

 my $message = $obj->message;

Get comment message.

Returns string.

=head1 EXAMPLE

=for comment filename=fixture.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Data::Message::Board::Example;

 my $obj = Test::Shared::Fixture::Data::Message::Board::Example->new;

 # Print out.
 print 'Author name: '.$obj->author->name."\n";
 print 'Date: '.$obj->date."\n";
 print 'Id: '.$obj->id."\n";
 print 'Message: '.$obj->message."\n";
 print "Comments:\n";
 map {
         print "\tAuthor name: ".$_->author->name."\n";
         print "\tDate: ".$_->date."\n";
         print "\tId: ".$_->id."\n";
         print "\tComment: ".$_->message."\n\n";
 } @{$obj->comments};

 # Output:
 # Author name: John Wick
 # Date: 2024-05-25T17:53:20
 # Id: 7
 # Message: How to install Perl?
 # Comments:
 #         Author name: Gregor Herrmann
 #         Date: 2024-05-25T17:53:27
 #         Id: 1
 #         Comment: apt-get update; apt-get install perl;
 # 
 #         Author name: Emmanuel Seyman
 #         Date: 2024-05-25T17:53:37
 #         Id: 2
 #         Comment: dnf update; dnf install perl-intepreter;
 # 

=head1 DEPENDENCIES

L<Data::Message::Board>,
L<Data::Message::Board::Comment>,
L<Data::Person>,
L<DateTime>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Message-Board>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
