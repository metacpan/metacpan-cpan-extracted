package App::Actions::I18N::zh;

use strict;
use warnings;
use utf8;

our $VERSION = '0.002.1';

# The Chinese catalogue: message key to text, or to a hash that chooses a
# text by gender or plural category; see App::Actions::I18N for the shape.
# Every key here must also be in the English catalogue, with the same
# placeholders, which t/i18n.t checks.
my %MESSAGES = (
	'actions.workflow_file_required' => '必须提供 workflow_file',
	'actions.workflow_file_missing' => "工作流文件 '%(file)s' 不存在",
	'actions.project_dir_required' => '工作流不在 .github/workflows 目录中时必须提供 project_dir',
	'actions.project_dir_missing' => "项目目录 '%(dir)s' 不存在",
	'actions.document_required' => '必须提供文档名称',
	'actions.document_unknown' => "未知文档 '%(name)s'；应为 %(expected)s",
	'actions.invalid_arguments' => '%(routine)s 的参数无效：%(reason)s',
	'list.or' => '%(head)s 或 %(last)s',

	'workflow.file_required' => '未提供工作流文件',
	'workflow.file_missing' => "工作流文件 '%(file)s' 不存在",
	'workflow.parse_failed' => "无法解析工作流 '%(file)s'：%(error)s",
	'workflow.empty' => "工作流 '%(file)s' 为空",
	'workflow.not_mapping' => "工作流 '%(file)s' 必须包含一个 YAML 映射",
	'workflow.no_jobs' => "工作流 '%(file)s' 没有 'jobs' 映射",
	'workflow.job_not_mapping' => "作业 '%(job)s' 必须是一个映射",
	'workflow.job_no_steps' => "作业 '%(job)s' 没有 'steps' 列表",
	'workflow.container_invalid' => "作业 '%(job)s' 的 container 必须是映射或字符串",
	'workflow.services_invalid' => "作业 '%(job)s' 的 services 必须是映射",
	'workflow.runs_on_invalid' => "'runs-on' 必须是字符串或列表",
	'workflow.matrix_not_mapping' => 'strategy.matrix 必须是映射',
	'workflow.matrix_empty' => "矩阵键 '%(key)s' 必须是至少包含一个值的列表",
	'workflow.exclude_invalid' => "矩阵的每个 'exclude' 条目必须是映射",
	'workflow.include_invalid' => "矩阵的每个 'include' 条目必须是映射",
	'workflow.defaults_run_invalid' => '%(where)s 的 run 必须是映射',

	'action.dir_required' => '未提供 action 目录',
	'action.dir_missing' => "action 目录 '%(dir)s' 不存在",
	'action.no_metadata' => "在 '%(dir)s' 中找不到 action.yml 或 action.yaml",
	'action.file_required' => '未提供 action 元数据文件',
	'action.file_missing' => "action 元数据文件 '%(file)s' 不存在",
	'action.parse_failed' => "无法解析 action 元数据 '%(file)s'：%(error)s",
	'action.empty' => "action 元数据 '%(file)s' 为空",
	'action.not_mapping' => "action 元数据 '%(file)s' 必须包含一个 YAML 映射",
	'action.no_runs' => "action 元数据 '%(file)s' 没有 'runs' 映射",
	'action.no_using' => "action 元数据 '%(file)s' 没有 'runs.using'",
	'action.no_steps' => "组合 action '%(file)s' 没有 'runs.steps' 列表",
	'action.no_main' => "JavaScript action '%(file)s' 没有 'runs.main'",
	'action.inputs_invalid' => "'%(file)s' 的 'inputs' 必须是映射",
	'action.input_invalid' => "'%(file)s' 的输入 '%(name)s' 必须是映射",
	'action.outputs_invalid' => "'%(file)s' 的 'outputs' 必须是映射",
	'action.output_invalid' => "'%(file)s' 的输出 '%(name)s' 必须是映射",

	'step.not_mapping' => '%(where)s 中的一个步骤不是映射',
	'step.field_not_string' => "%(where)s 中的步骤字段 '%(field)s' 必须是字符串",
	'step.no_command' => "%(where)s 中的一个步骤既没有 'run' 也没有 'uses'",
	'mapping.invalid' => '%(where)s 必须是映射',

	'where.job' => "作业 '%(job)s'",
	'where.file' => "'%(file)s'",
	'where.workflow_env' => '工作流的 env',
	'where.workflow_defaults' => '工作流的 defaults',
	'where.job_env' => "作业 '%(job)s' 的 env",
	'where.job_defaults' => "作业 '%(job)s' 的 defaults",
	'where.job_strategy' => "作业 '%(job)s' 的 strategy",
	'where.step_env' => '%(where)s 中某个步骤的 env',
	'where.step_with' => '%(where)s 中某个步骤的 with',

	'i18n.unknown_key' => "没有为 '%(key)s' 定义消息",
	'i18n.unknown_language' => "语言 '%(language)s' 没有消息目录；改用英语",

	'span.second' => { plural => { other => '%(count)d 秒' } },
	'span.minute' => { plural => { other => '%(count)d 分钟' } },
	'span.hour' => { plural => { other => '%(count)d 小时' } },
	'span.day' => { plural => { other => '%(count)d 天' } },
	'span.month' => { plural => { other => '%(count)d 个月' } },
	'span.year' => { plural => { other => '%(count)d 年' } },

	'cache.summary' => { plural => { other => '%(count)d 个镜像。' } },
	'cache.summary_sized' => { plural => { other => '%(count)d 个镜像，占用磁盘 %(size)s。' } },
	'cache.missing' => { plural => { other => '%(count)d 个镜像已不在守护进程中。' } },
	'cache.removed' => { plural => { other => '已删除 %(count)d 个镜像，释放 %(size)s。' } },
	'cache.forgot' => { plural => { other => '已遗忘 %(count)d 个不在守护进程中的镜像。' } },
	'cache.remove_failed' => { plural => { other => '无法删除 %(count)d 个镜像：' } },

	'logs.summary' => { plural => { other => '%(count)d 个日志，占用磁盘 %(size)s。' } },
	'logs.removed' => { plural => { other => '已删除 %(count)d 个日志，释放 %(size)s。' } },
	'logs.remove_failed' => { plural => { other => '无法删除 %(count)d 次运行：' } },
	# The text listings of the cache and logs commands.
	'span.just_now' => '刚刚',
	'span.ago' => '%(span)s前',
	'cache.file' => '缓存文件：%(file)s',
	'cache.empty' => '尚未缓存任何镜像。',
	'cache.none_older' => '没有超过 %(span)s 的缓存镜像。',
	'cache.only_older' => '仅显示超过 %(span)s 的镜像。',
	'cache.unreachable' => '无法连接 Docker 守护进程，因此大小未知。',
	'cache.prune_hint' => '使用 "action-run cache --prune" 删除它们。',
	'cache.unknown' => '未知',
	'cache.size_missing' => '缺失',
	'cache.heading.image' => '镜像',
	'cache.heading.size' => '大小',
	'cache.heading.last_used' => '上次使用',
	'cache.heading.age' => '距今',
	'logs.directory' => '日志目录：%(directory)s',
	'logs.empty' => '尚未保留任何作业日志。',
	'logs.none_older' => '没有超过 %(span)s 的作业日志。',
	'logs.only_older' => '仅显示超过 %(span)s 的作业日志。',
	'logs.prune_hint' => '使用 "action-run logs --prune" 删除它们。',
	'logs.heading.run' => '运行',
	'logs.heading.log' => '日志',
	'logs.heading.size' => '大小',
	'logs.heading.age' => '距今',
	'process.redirect_failed' => "无法将 %(stream)s 重定向到 '%(file)s'：%(error)s",
	'process.exec_failed' => "无法运行 '%(program)s'：%(error)s",
	# The runner and its parts.  "action-run: " is the program's name and is
	# not translated; the line markers (==>, ---, !!) are kept too.
	'runner.workflow_required' => '必须提供工作流',
	'runner.project_dir_required' => '必须提供项目目录',
	'runner.project_dir_missing' => "项目目录 '%(dir)s' 不存在",
	'runner.pull_concurrency_invalid' => "拉取并发数必须是正整数，而不是 '%(value)s'",
	'runner.pull_conflict' => '--pull 与 --no-pull 不能同时使用',
	'runner.interrupted' => '已中断',
	'runner.terminated' => '已终止',
	'runner.error' => 'action-run: %(error)s',
	'runner.not_ready' => '环境尚未就绪；请按上方报告的要求修复，或使用 --skip-check 强制运行',
	'runner.no_job_matched' => "没有与 '%(filter)s' 匹配的作业",
	'runner.dependency_cycle' => "作业 '%(job)s' 存在循环依赖",
	'runner.unknown_job' => "未知作业 '%(job)s'",
	'runner.need_not_selected' => "action-run: 作业 '%(job)s' 依赖未被选中的 '%(need)s'；假定其已成功",
	'runner.env_cycle' => "环境变量 '%(name)s' 直接或通过其他变量引用了自身",
	'runner.env_failed' => "无法求值环境变量 '%(name)s'：%(error)s",
	'runner.write_failed' => '无法写入%(what)s：%(error)s',
	'runner.file_write_failed' => "无法写入 '%(file)s'：%(error)s",
	'runner.file_read_failed' => "无法读取 '%(file)s'：%(error)s",
	'runner.network_failed' => "无法创建 Docker 网络 '%(name)s'（退出码 %(status)s）",
	'runner.input_required' => "操作 '%(uses)s' 需要输入 '%(name)s'",
	'runner.local_action_empty' => "本地操作 '%(uses)s' 未指向项目中的目录",
	'runner.local_action_escapes' => "本地操作 '%(uses)s' 不得超出项目目录",

	'runner.preflight.buffer_failed' => '无法缓冲预检报告：%(error)s',
	'runner.preflight.remedy_image' => '请检查镜像名称、仓库是否可达以及 Docker 登录是否有效',
	'runner.preflight.schema_line' => '  模式      版本 %(version)s (action-run schema preflight)',
	'runner.preflight.schema_mismatch' => 'action-run preflight --json 文档与 App::Actions::Runner->json_schema 不符',
	'runner.preflight.image' => '  镜像      %(name)s（%(source)s）：%(status)s',
	'runner.preflight.deferred' => '  延后      %(error)s',
	'runner.preflight.unnamed' => '（未命名）',
	'runner.preflight.workflow' => '工作流',

	'runner.source.job' => "作业 '%(name)s'",
	'runner.source.service' => "作业 '%(name)s' 的服务 '%(id)s'",
	'runner.source.action' => "作业 '%(name)s' 中的操作 '%(uses)s'",
	'runner.source.nested_action' => "作业 '%(name)s' 的本地操作 '%(via)s' 中的操作 '%(uses)s'",

	'runner.image.pulling' => '正在拉取镜像 %(image)s...',
	'runner.image.pull_failed' => "拉取 Docker 镜像 '%(image)s' 失败（退出码 %(status)s）",
	'runner.image.unresolved' => "无法解析 %(source)s 所需的镜像 '%(expression)s'：%(error)s",
	'runner.image.unprepared' => "无法准备 %(source)s 所需的镜像 '%(image)s'：%(error)s",
	'runner.image.empty' => '镜像名称为空',
	'runner.image.not_local' => "Docker 镜像 '%(image)s' 在本地不可用（--no-pull）",
	'runner.image.checking' => '  镜像      %(image)s（%(source)s）',
	'runner.image.cache_failed' => 'action-run: 无法更新镜像缓存：%(error)s',

	'runner.job.if_failed' => "action-run: 无法求值 '%(name)s' 的 if：%(error)s",
	'runner.job.skipped' => '==> 作业：%(name)s（已跳过）',
	'runner.job.fail_fast' => '==> 作业：%(name)s（因 fail-fast 跳过）',
	'runner.job.continue_failed' => "action-run: 无法求值 '%(name)s' 的 continue-on-error：%(error)s",
	'runner.job.continued' => '!! 作业失败，但设置了 continue-on-error：%(name)s',
	'runner.job.not_linux' => "==> 作业：%(name)s（已跳过：runs-on '%(runs_on)s' 不是 Linux）",
	'runner.job.unsupported_runner' => '不支持的运行器：%(runs_on)s',
	'runner.job.start' => '==> 作业：%(name)s',
	'runner.job.no_image' => "无法确定作业 '%(name)s' 的容器镜像",
	'runner.job.image' => '    镜像：%(image)s',
	'runner.job.deferred' => '  延后      %(expression)s（%(source)s）',

	'runner.parallel.did_not_run' => "作业 '%(name)s' 未运行",
	'runner.parallel.dup_failed' => '无法复制 %(handle)s',
	'runner.parallel.restore_failed' => '无法恢复 %(handle)s',

	'runner.service.not_mapping' => "服务 '%(id)s' 必须是映射",
	'runner.service.no_image' => "服务 '%(id)s' 没有镜像",
	'runner.options_invalid' => "无法读取容器选项 '%(options)s'：有引号未闭合",
	'runner.service.credentials' => "action-run: 不支持服务 '%(id)s' 的凭据；将使用本地 Docker 登录",
	'runner.service.start_failed' => "无法启动服务 '%(id)s'（退出码 %(status)s）",
	'runner.what.service' => "服务 '%(id)s'",
	'runner.what.job_container' => "作业容器 '%(name)s'",
	'runner.what.step_script' => "步骤脚本 '%(file)s'",
	'runner.what.step_file' => "步骤文件 '%(file)s'",
	'runner.shared_files' => "action-run: 作业以 '%(user)s' 身份运行，因此其运行器目录 %(dir)s 对本机所有用户开放，而其中的步骤脚本包含工作流的机密；请以您自己的用户或 root 身份运行作业以保持其私密",
	'runner.what.sudo_shim' => 'sudo 替身',
	'runner.what.apt_shim' => '%(name)s 替身',

	'runner.container.dead' => '%(what)s 已停止工作',
	'runner.container.restarting' => '%(what)s 正在重启',
	'runner.container.with_count' => '%(state)s（重启次数 %(count)s）',
	'runner.container.count_unknown' => '%(state)s（无法读取重启次数）',
	'runner.container.stopped' => '%(what)s 未能保持运行（退出码 %(status)s）',
	'runner.container.stopped_unknown' => '%(what)s 未能保持运行（无法读取退出状态）',
	'runner.container.start_failed' => '%(what)s 无法启动（退出码 %(status)s）',
	'runner.container.at_fault' => '%(state)s；原因：%(fault)s',
	'runner.container.silent' => '%(state)s；它没有任何输出',
	'runner.container.output' => '%(state)s；它最后的输出是：',
	'runner.container.daemon_silent' => '%(state)s；守护进程没有给出任何信息',
	'runner.container.daemon_said' => '%(state)s；守护进程报告：',
	'runner.fault.image' => "镜像 '%(image)s'",
	'runner.fault.port' => '发布的端口',
	'runner.fault.entrypoint' => "入口点 '%(entrypoint)s'",

	'runner.explain.service' => "作业 '%(job)s' 的服务 '%(id)s'",
	'runner.explain.job' => "作业 '%(job)s'",
	'runner.explain.action' => "作业 '%(job)s' 中的操作 '%(uses)s'",
	'runner.explain.title' => '==> %(title)s',
	'runner.explain.container' => '    容器       %(name)s',
	'runner.explain.image' => '    镜像       %(image)s',
	'runner.explain.entrypoint' => '    入口点     %(entrypoint)s',
	'runner.explain.command' => '    命令       %(command)s',
	'runner.explain.image_own' => '（镜像自带）',

	'runner.step.env_failed' => "action-run: 无法求值步骤 '%(step)s' 的环境：%(error)s",
	'runner.step.if_failed' => "action-run: 无法求值步骤 '%(step)s' 的 if：%(error)s",
	'runner.step.skipped' => '--- 步骤：%(name)s（已跳过）',
	'runner.step.start' => '--- 步骤：%(name)s',
	'runner.step.summary_header' => '--- 步骤摘要 ---',
	'runner.step.continue_failed' => 'action-run: 无法求值 continue-on-error：%(error)s',
	'runner.step.continued' => '!! 步骤失败，但设置了 continue-on-error',
	'runner.step.failed_default' => '步骤失败',
	'runner.step.failure' => '!! %(message)s',
	'runner.step.exited' => '步骤以状态 %(status)s 退出',
	'runner.step.default_name' => '步骤 %(number)s',
	'runner.post.if_failed' => "action-run: 无法求值 '%(uses)s' 的 post 条件：%(error)s",
	'runner.post.start' => '--- 步骤：Post %(uses)s',
	'runner.post.failed' => "action-run: '%(uses)s' 的 post 步骤失败：%(error)s",
	'runner.post.exited' => "!! '%(uses)s' 的 post 步骤以状态 %(status)s 退出",
	'runner.shell.missing' => "容器中没有 shell '%(shell)s'",
	'runner.script.begin' => '--- 脚本 ---',
	'runner.script.end' => '--- 脚本结束 ---',
	'runner.checkout.path' => "action-run: 忽略 actions/checkout 的 'path'；仓库已挂载在 /github/workspace",
	'runner.checkout.submodules' => 'action-run: 不获取 actions/checkout 的子模块；按原样使用当前检出',
	'runner.checkout.ref' => 'action-run: 忽略 actions/checkout 的 ref/repository；使用本地检出',
	'runner.noop' => '    （%(message)s）',
	'runner.noop.checkout' => '仓库已挂载在 /github/workspace',
	'runner.noop.perl' => '使用容器镜像中的 Perl',
	'runner.noop.perl_version' => '使用容器镜像中的 Perl %(version)s',
	'runner.noop.cache' => '缓存、制品和覆盖率上传尚未实现',
	'runner.unsupported.remote' => '不支持远程 JavaScript 和组合操作',
	'runner.unsupported.using' => "不支持使用 '%(using)s' 的本地操作",
	'runner.unsupported.skipped' => "已跳过操作 '%(action)s'：%(reason)s",
	'runner.unsupported.note' => '    （已跳过：%(reason)s）',
	'runner.docker_action.no_image' => "作业 '%(job)s' 中的 Docker 操作 '%(uses)s' 没有镜像名称；请检查它使用的表达式",
	'runner.docker_action.bad_args' => "无法读取 '%(uses)s' 的 args（'%(args)s'）：有引号未闭合",
	'runner.docker_action.bad_image' => "作业 '%(job)s' 中的 Docker 操作 '%(uses)s' 解析为 '%(image)s'，这不是镜像名称；请检查它使用的表达式",
	'runner.docker_action.exited' => 'Docker 操作以状态 %(status)s 退出',
	'runner.local_action.missing' => "本地操作 '%(uses)s' 不存在（查找位置：%(dir)s）",
	'runner.composite.too_deep' => "组合操作 '%(uses)s' 的嵌套超过 %(depth)s 层",
	'runner.composite.failed' => "组合操作 '%(uses)s' 失败",
	'runner.javascript.no_node' => "JavaScript 操作 '%(uses)s' 需要 Node.js，但在作业容器中找不到 'node'",
	'runner.javascript.pre_if_failed' => "action-run: 无法求值 '%(uses)s' 的 pre-if：%(error)s",
	'runner.javascript.pre_exited' => "JavaScript 操作 '%(uses)s' 的 pre 步骤以状态 %(status)s 退出",
	'runner.javascript.exited' => "JavaScript 操作 '%(uses)s' 以状态 %(status)s 退出",

	'runner.summary.header' => '=== 工作流摘要 ===',
	'runner.summary.none' => '  没有运行任何作业。',
	'runner.summary.failed' => '工作流失败',
	'runner.summary.succeeded' => '工作流成功',
	'runner.logs.kept' => '作业日志保存在 %(dir)s',
	'runner.logs.keep_failed' => 'action-run: 无法保存作业日志：%(error)s',
	'runner.logs.copy_failed' => "无法将 '%(from)s' 复制到 '%(to)s'：%(error)s",
	'runner.logs.bad_name' => "'%(name)s' 不是简单的文件名",
	'runner.kept.header' => '保留的 Docker 资源：',
	'runner.kept.container' => '  容器 %(name)s',
	'runner.kept.network' => '  网络 %(name)s',
	'runner.kept.temp' => '  临时目录 %(dir)s',
);

# messages
# Purpose:     Hand the catalogue to App::Actions::I18N.
# Entry:       None.
# Exit status: Returns a new hash reference, so the caller may change it.
# Side effects: None.
sub messages {
	return { %MESSAGES };
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::I18N::zh - the Chinese message catalogue of App::Actions

=head1 SYNOPSIS

You do not normally use this module directly.  Choose the language through
L<App::Actions::I18N>:

	use App::Actions::I18N;

	my $i18n = App::Actions::I18N->new(language => 'zh');
	binmode STDOUT, ':encoding(UTF-8)';
	print $i18n->message('workflow.empty', { file => 'ci.yml' }), "\n";
	# (the Chinese text of the message)

Or for a whole run of the command:

	ACTION_RUN_LANG=zh action-run run .github/workflows/ci.yml

Read the catalogue itself, for example to check a translation:

	use App::Actions::I18N::zh;

	my $entries = App::Actions::I18N::zh->messages;
	print scalar(keys %{$entries}), " messages\n";

=head1 DESCRIPTION

This module holds the Chinese texts of App::Actions' messages.  A key that is missing here is shown in English
instead.

Data only: L<App::Actions::I18N> loads it and renders its entries.  Keys,
placeholders and the plural and gender forms are described there.

=head1 METHODS

=head2 messages

Returns a hash reference of message key to entry.

=head3 EXAMPLE

	my $entries = App::Actions::I18N::zh->messages;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => q{hashref} }

=head3 MESSAGES

None.

=head1 COMMON PITFALLS

=over 4

=item * B<Do not change the returned hash to translate.>  L</messages>
returns a copy, so changes to it are lost.  Use
L<App::Actions::I18N/add_messages>.

=item * B<Keep the placeholders.>  A translation must use the same
placeholder names as the English text, for example C<%(file)s>.  The test
F<t/i18n.t> checks this.

=item * B<Plurals follow the Chinese rule.>  Chinese does not change words for number, so every count uses the C<other> form.

=item * B<C<LANG> does not choose this language.>  Use C<ACTION_RUN_LANG=zh>
or the C<language> argument.

=back

=head1 ENCODING

The source file is UTF-8 and uses C<use utf8>, so every text is a Perl
character string.  The texts contain non-ASCII characters (Chinese
characters), and may contain any Unicode character.  Encode the text when you
print it, for example with C<binmode STDOUT, ':encoding(UTF-8)'>, or Perl
prints a "Wide character" warning.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.  It is for readers who want to check exactly what a routine
promises.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞState> means the routine changes
nothing, and C<ΔState> means it can change the state.  The lines below the
rule are the conditions that are always true when the routine returns.

	KEY == { k : seq CHAR | k matches [a-z][a-z0-9_]*(\.[a-z0-9_]+)+ }
	ENTRY ::= text⟨⟨seq CHAR⟩⟩
	        | plural⟨⟨{one, other} ⇸ seq CHAR⟩⟩
	        | gender⟨⟨{female, male, other} ⇸ ENTRY⟩⟩
	MESSAGES : KEY ⇸ ENTRY             the fixed catalogue in this file

=head2 messages

	┌─ Messages ────────────────────────────────────────
	│ r! : KEY ⇸ ENTRY
	├───────────────────────────────────────────────────
	│ r! = MESSAGES
	│ r! is a new hash each call: changing it leaves MESSAGES unchanged
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The catalogue never changes.  This is how one of its texts is used:

	 App::Actions::I18N->new(language => 'zh')
	 (or ACTION_RUN_LANG=zh, or a country that speaks Chinese)
	        |
	        v
	+---------------------+  message($key, \%args)
	| TRANSLATOR (zh)   |------------------------+
	+---------------------+                        |
	                                               v
	                      +-------------------------------------+
	                      | $key in this catalogue?             |
	                      +-------------------------------------+
	                           | yes                     | no
	                           v                         v
	                  +----------------+      +----------------------+
	                  | entry from     |      | English entry        |
	                  | this module    |      | (App::Actions::I18N::|
	                  +----------------+      |  en); none: the key  |
	                           |              +----------------------+
	                           +-----------+-----------+
	                                       v
	                  gender form, then plural form (Chinese rule),
	                  then the %(name)s placeholders filled in
	                                       |
	                                       v
	                               the finished text

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
