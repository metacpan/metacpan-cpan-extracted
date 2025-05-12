# App::BlurFill

A simple Perl class for generating blurred background fills for images. Suitable for use in video formatting, social posts, and more.

## Usage

```perl
use App::BlurFill;

my $blur = App::BlurFill->new(file => 'input.jpg');
$blur->process;  # writes input_blur.jpg
```
