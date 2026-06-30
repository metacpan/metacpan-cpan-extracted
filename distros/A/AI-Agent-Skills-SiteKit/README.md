# AI Agent Skills Site Kit

Small metadata and URL helpers for [AI Agent Skills](https://aiagentskills.net), a curated directory for discovering Claude skills, Codex skills, and AI agent workflows.

## Useful links

- Website: <https://aiagentskills.net>
- [AI agent skills directory](https://aiagentskills.net/skills/): browse curated agent skills.
- [Claude and Codex skill search](https://aiagentskills.net/skills/?q=seo): build stable search URLs for skill discovery.
- [Submit an AI agent skill](https://aiagentskills.net/submit/): submit a useful public skill for review.
- [AI agent skills blog](https://aiagentskills.net/blog/): read guides and updates.
- [Agent workflow skills](https://aiagentskills.net/category/agent-workflows/): browse workflow and automation skills.
- [Code generation skills](https://aiagentskills.net/category/code-generation/): browse development-focused skills.

## What this package does

Each ecosystem package exposes tiny helpers for site metadata and stable URL construction. It is intentionally boring: no network calls, no hidden behavior, and no claim that this is an official SDK.

## Common API

- `homeUrl` / `home_url`: homepage URL.
- `skillsUrl` / `skills_url`: skills directory URL.
- `searchUrl(query)` / `search_url(query)`: skills search URL.
- `submitUrl` / `submit_url`: skill submission URL.
- `blogUrl` / `blog_url`: blog URL.
- `categoryUrl(slug)` / `category_url(slug)`: category URL.
- `skillUrl(slug)` / `skill_url(slug)`: individual skill URL.
- `metadata`: brand, homepage, description, canonical pages, and tags.

## License

MIT.
