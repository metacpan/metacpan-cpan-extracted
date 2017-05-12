package Apache::ASP::Lang::PerlScript;

sub new { 
    my($class, %args) = shift;
    bless \%args, $class;
};

sub CommentStart { '#' };

1;
