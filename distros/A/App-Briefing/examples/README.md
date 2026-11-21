# briefing examples

Drop these into a project to verify the plugin works end-to-end:

```
cp examples/agents/briefing-demo.md       <project>/.claude/agents/
cp -r examples/skills/briefing-demo-skill <project>/.claude/skills/
```

Then ask Claude Code to spawn the `briefing-demo` subagent. If the
plugin is active, the subagent will report back the magic phrase from
`briefing-demo-skill/SKILL.md` — proving the skill body was in its
context before its first turn, with no `Skill` tool call.

To prove the hard-fail path, edit `briefing-demo.md` and add a
non-existent skill name to the `skills:` list, then spawn again. The
spawn will be denied with a clear error message.
