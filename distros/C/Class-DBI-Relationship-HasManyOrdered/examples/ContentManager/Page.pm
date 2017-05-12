package ContentManager::Page;
use base 'ContentManager::DBI';

use ContentManager::Image;

ContentManager::Page->table('pages');
ContentManager::Page->columns(All => qw/page_id title date_to_publish date_to_archive/);
# ContentManager::Page->has_a(category => Category);
# ContentManager::Page->has_many(authors => Authors);
# ContentManager::Page->has_many_ordered(paragraphs => Paragraphs => {sort => 'position', map => 'PageParagraphs'});
ContentManager::Page->has_many_ordered(Images => ContentManager::Image =>  image_id, {order_by => 'position', map => 'pageimages'});
