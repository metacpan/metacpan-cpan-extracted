#include "FS.hpp"
#include <iostream>
#include <algorithm>

namespace FS {

	// implementation for asterisk matching
	// http://stackoverflow.com/q/30823596/1550314
	// not sure if this work 100% correctly with backtracking
	// but good starting point to add more pattern matchings
	bool pmatch(const std::string& text, const std::string& pattern)
	{

		// naked asterisk pattern does not match these
		if (pattern == "" && text == "/") return true;
		if (pattern == "*" && text[0] == '.') return false;
		if (pattern == "*" && text[0] == '$') return false;
		if (pattern == "*") return text != "." && text != "..";

		// get iterators for pattern and for entry name
		std::string::const_iterator pat = pattern.begin();
		std::string::const_iterator pat_end = pattern.end();
		std::string::const_iterator it = text.begin();
		std::string::const_iterator end = text.end();

		// loop until both iterators are done
		while (it != end && pat != pat_end)
		{
			// get the current char
			const char c = *pat;
			// matches pattern
			if (*it == c)
			{
				// forward
				++it;
				++pat;
			}
			// wildcard goes into inner loop
			else if (c == '*')
			{
				// forward pattern
				++pat;
				// consume the rest
				if (pat == pat_end)
				{
					// we matched
					return true;
				}
				// store the trackback pointer
				std::string::const_iterator save = pat;
				// number to determine best match
				std::size_t matched_chars = 0;
				// inner loop (same abort condition)
				while (it != end && pat != pat_end)
				{
					// matches pattern
					if (*it == *pat)
					{
						// forward
						++it;
						++pat;
						// acount match
						++matched_chars;
						// the pattern is exhausted, but the
						// string is not matched, so back up!
						if (pat == pat_end && it != end)
						{
							pat = save;
							matched_chars = 0;
							// Check for an overlap and back up
							// the input iterator if necessary
							std::size_t d1 = std::distance(it, end);
							std::size_t d2 = std::distance(pat, pat_end);
							if (d2 > d1) it -= (d2 - d1);
						}
					}
					else if (*pat == '*')
					{
						break;
					}
					else
					{
						if (pat == save) ++it;
						pat = save;
						matched_chars = 0;
					}
				}
			}
			else break;
		}
		// trailing wildcard allowed
		while(*pat == '*') ++pat;
		// check if we matched completely
		return it == end && pat == pat_end;
	}
	// EO pmatch

	// return path without trailing slash
	const std::string Entry::path() const
	{
		// reached the root directory?
		if (this == parent) {
			if (parent->name == "") {
				return "/" + this->name;
			} else if (this->name != ".") {
				return this->name;
			} else {
				return ".";
			}
		}
		// child directory
		else if (parent) {
			// return base plus current
			std::string base(parent->path());
			if (base != "/") base += "/";
			return base + this->name;
		}
		// should not happen?
		else {
			// just the name
			return this->name;
		}
	}

	// helper to compare/sort pointer objects
	static bool comparePtrToNode(Entry* a, Entry* b)
	{
		// may be same object
		if (a == b) return true;
		// move nulls to top
		if (a == NULL) return true;
		if (b == NULL) return false;
		// query if directories
		bool isDirA = a->isDirectory();
		bool isDirB = b->isDirectory();
		// only one directory
		if (isDirA != isDirB) {
			// move directory up
			return b->isDirectory();
		}
		// should move up
		return (*a < *b);
	}

	// main method to get our sub children
	const std::vector<Entry*>& Entry::getEntries()
	{
		// special directory nodes contain the same as parent or grandparent node
		// we should force collapse here to avoid that we read them multiple times
		// need to account for reference matching with how we store the path found
		if (collapse && parent && this != parent) {
			if (name == ".") return parent->getEntries();
			if (name == "..") return parent->parent->getEntries();
		}
		// check if we already loaded the children
		if (this->loaded == true) return this->entries;
		// maybe we already know it is not a directory?
		if (this->directory == false) return this->entries;
		// get the full path to the directory
		std::string path(this->path() + "/");
		// try to open directory handle
		if(DIR *dh = opendir(path.c_str())) {
			// read in all entries from directory
			while (struct dirent* entry = readdir(dh)) {
				if (const char* name = entry->d_name) {
					this->add(std::string(name));
				}
			}
			// release handle
			closedir(dh);
		}
		// directory fail
		// assume wrong type
		else {
			this->directory = false;
		}
		// update status flag
		this->fetched = true;
		this->loaded = true;
		// enfore alphanumeric order
		std::sort(entries.begin(), entries.end(), comparePtrToNode);
			// return entries
		return this->entries;
	}

	// execute search on current node
	void Match::execute(Entry& entry)
	{

		// abort if end level reached
		if (lvl == patterns.size()) {
			if (entry.matched == false) {
				bool dir = entry.isDirectory();
				if (!directory || dir) {
					entry.matched = true;
					matches.push_back(&entry);
				}
			}
			return;
		}

		// get pattern part for current level
		const std::string& pattern = patterns.at(lvl);

		// special case when ending with empty pattern
		// we should only match directories (the parent)
		if (pattern.empty() && lvl + 1 == patterns.size())
		{
			this->lvl += 1;
			if (entry.parent != NULL)
			{ this->execute(*entry.parent); }
			else { this->execute(entry); }
			this->lvl -= 1;
		}
		// dispatch starglob matching
		else if (pattern == "**") {
			this->lvl += 1;
			this->recursive(entry);
			this->lvl -= 1;
		}
		// match this entry name
		else if (pmatch(entry.name, pattern)) {
			// test if we exhausted patterns
			// means we must not go any deeper
			if (lvl + 1 == patterns.size()) {
				if (entry.matched == false) {
					entry.matched = true;
					matches.push_back(&entry);
				}
			}
			// should we filter directories
			else if (patterns.at(lvl + 1).empty()) {
				if (entry.matched == false) {
					entry.matched = true;
					if (entry.isDirectory())
						matches.push_back(&entry);
				}
			}
			// check next partial pattern
			else {
				// get iterators for child entries
				const std::vector<Entry*>& entries = entry.getEntries();
				std::vector<Entry*>::const_iterator it = entries.begin();
				std::vector<Entry*>::const_iterator end = entries.end();
				this->lvl += 1;
				while (it != end) {
					Entry* child = *it;
					this->execute(*child);
					it += 1;
				}
				this->lvl -= 1;
			}
		}
	}
	// EO execute

	// match recursively on children
	void Match::recursive(Entry& entry)
	{
		if (lvl == patterns.size()) {
			// do not visit certain nodes
			if (entry.name == ".") return;
			if (entry.name == "..") return;
			if (entry.name[0] == '.') return;
			if (entry.name[0] == '$') return;
		}
		// apply on ourself
		this->execute(entry);
		// do not visit certain nodes
		if (entry.name == ".") return;
		if (entry.name == "..") return;
		if (entry.name[0] == '.') return;
		if (entry.name[0] == '$') return;
		// get iterators for entries and apply recursive
		const std::vector<FS::Entry*>& entries = entry.getEntries();
		std::vector<FS::Entry*>::const_iterator it = entries.begin();
		std::vector<FS::Entry*>::const_iterator end = entries.end();
		while (it != end) {
			FS::Entry* child = *it;
			this->recursive(*child);
			it += 1;
		}
	}
	// EO recursive

}
