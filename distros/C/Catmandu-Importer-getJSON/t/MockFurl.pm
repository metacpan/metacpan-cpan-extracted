package MockFurl;
sub new { bless { @_ }, 'MockFurl' }
sub decoded_content {
    my $content = $_[0]->{content};
    ref $content ? $content->() : $content; 
}
sub urls { $_[0]->{urls} // [] } 
sub get { push @{$_[0]->{urls}}, $_[1]; $_[0] }
sub is_success { 1 }
1;
