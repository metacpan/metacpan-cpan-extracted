package ContentManager::Image;
use base 'ContentManager::DBI';

ContentManager::Image->table('images');
ContentManager::Image->columns(All => qw/image_id name position filename/);
ContentManager::Image->has_many_ordered(pages => ContentManager::Page => {order_by => 'position', map => 'pageimages'});

1;
