#include <sqlite_queue.h>

void
sqlite_queue::next()
{
	item_type item;
	{
		std::lock_guard<std::mutex> guard { mutex_ };
		if(pending_.empty()) {
			return;
		}
		item = pending_.front();
		pending_.pop();
	}
	(item)();
	next();
}

void
sqlite_queue::push(item_type &&req)
{
	std::lock_guard<std::mutex> guard { mutex_ };
	pending_.emplace(std::move(req));
}
