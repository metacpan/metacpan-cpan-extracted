#pragma once
#include <mutex>
#include <memory>
#include <queue>

class sqlite_queue {
public:
	using item_type = std::function<void()>;

	sqlite_queue() { }
	void next();
	void push(item_type &&req);

private:
	std::queue<item_type> pending_;
	std::mutex mutex_;
};

