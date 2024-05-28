package Data::Message::Board;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils 0.28 qw(check_array_object check_isa check_length check_number_id
	check_required);

our $VERSION = 0.01;

has author => (
	is => 'ro',
);

has comments => (
	default => [],
	is => 'ro',
);

has date => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has message => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check author.
	check_required($self, 'author');
	check_isa($self, 'author', 'Data::Person');

	# Check comments.
	check_array_object($self, 'comments', 'Data::Message::Board::Comment', 'Comment');

	# Check date.
	check_required($self, 'date');
	check_isa($self, 'date', 'DateTime');

	# Check id.
	check_number_id($self, 'id');

	# Check message.
	check_required($self, 'message');
	check_length($self, 'message', 4096);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Message::Board - Data object for Message board.

=head1 SYNOPSIS

 use Data::Message::Board;

 my $obj = Data::Message::Board->new(%params);
 my $author = $obj->author;
 my $comments_ar = $obj->comments;
 my $date = $obj->date;
 my $id = $obj->id;
 my $message = $obj->message;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Message::Board->new(%params);

Constructor.

=over 8

=item * C<author>

Author object which is L<Data::Person> instance.

It's required.

=item * C<comments>

Message board comments which are L<Data::Mesaage::Board::Comment> instances.

Default value is [].

=item * C<date>

Date of comment which is L<DateTime> instance.

It's required.

=item * C<id>

Id.

Default value is undef.

=item * C<message>

Main comment message. Max length of message is 4096 character.

It's required.

=back

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

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                 Parameter 'comments' must be a array.
                         Value: %s
                         Reference: %s
                 Comment isn't 'Data::Message::Board::Comment' object.
                         Value: %s
                         Reference: %s
         From Mo::utils::check_isa():
                 Parameter 'author' must be a 'Data::Person' object.
                         Value: %s
                         Reference: %s
                 Parameter 'date' must be a 'DateTime' object.
                         Value: %s
                         Reference: %s
         From Mo::utils::check_length():
                 Parameter 'message' has length greater than '4096'.
                         Value: %s
         From Mo::utils::check_number_id():
                 Parameter 'id' must be a natural number.
                         Value: %s
         From Mo::utils::check_required():
                 Parameter 'author' is required.
                 Parameter 'date' is required.
                 Parameter 'message' is required.

=head1 EXAMPLE

=for comment filename=message_board.pl

 use strict;
 use warnings;

 use Data::Person;
 use Data::Message::Board;
 use Data::Message::Board::Comment;
 use DateTime;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 my $dt = DateTime->now;
 my $dt_comment1 = $dt->clone->add('minutes' => 5);
 my $dt_comment2 = $dt_comment1->clone->add('seconds' => 34);
 my $obj = Data::Message::Board->new(
         'author' => Data::Person->new(
                 'email' => 'skim@cpan.org',
                 'name' => decode_utf8('Michal Josef Špaček'),
         ),
         'comments' => [
                 Data::Message::Board::Comment->new(
                         'author' => Data::Person->new(
                                 'email' => 'bar@example.com',
                                 'name' => decode_utf8('St. John'),
                         ),
                         'date' => $dt_comment1,
                         'id' => 7,
                         'message' => 'I am fine.',
                 ),
                 Data::Message::Board::Comment->new(
                         'author' => Data::Person->new(
                                 'email' => 'foo@example.com',
                                 'name' => decode_utf8('John Wick'),
                         ),
                         'date' => $dt_comment2,
                         'id' => 6,
                         'message' => 'Not bad.',
                 ),
         ],
         'date' => $dt,
         'id' => 1,
         'message' => 'How are you?',
 );

 # Print out.
 print 'Author name: '.encode_utf8($obj->author->name)."\n";
 print 'Author email: '.$obj->author->email."\n";
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
 # Author name: Michal Josef Špaček
 # Author email: skim@cpan.org
 # Date: 2024-05-27T18:10:55
 # Id: 1
 # Message: How are you?
 # Comments:
 #         Author name: St. John
 #         Date: 2024-05-27T18:15:55
 #         Id: 7
 #         Comment: I am fine.
 # 
 #         Author name: John Wick
 #         Date: 2024-05-27T18:16:29
 #         Id: 6
 #         Comment: Not bad.
 # 

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Message-Board>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
