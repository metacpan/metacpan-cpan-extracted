# Conf-Libconfig Tools

本目录包含开发辅助工具，用于自动化 XS 绑定生成和代码覆盖率分析。

## 文件说明

### ParseSource.pl
解析 C 头文件 (`src/libconfig_perl.h`)，提取函数签名和类型定义。

```
perl tools/ParseSource.pl
```

依赖: `ExtUtils::XSBuilder` (`dnf install perl-ExtUtils-XSBuilder`)

### WrapXSCheck.pl
检查已有 XS 绑定与 C 头文件的差异，确认绑定完整性。需要 `xsbuilder/maps/` 目录下有对应的类型映射文件。

```
perl tools/WrapXSCheck.pl
```

依赖: `ExtUtils::XSBuilder`

### WrapXSRun.pl
基于 `ExtUtils::XSBuilder` 自动从 C 头文件生成 XS 绑定代码。需要 `xsbuilder/maps/` 目录下有对应的类型映射文件。

```
perl tools/WrapXSRun.pl
```

依赖: `ExtUtils::XSBuilder`

### coverage
运行 Perl + C (XS) 组合代码覆盖率测试，生成 HTML 格式的覆盖率报告。内部使用 `cover -test` 一键完成编译插桩、测试执行和报告生成。

```
bash tools/coverage
```

依赖:
- `Devel::Cover` — `dnf install perl-Devel-Cover`
- `gcov2perl` — 随 Devel::Cover 一起安装
- `gcc` (含 gcov)

## 依赖安装

```bash
# XSBuilder 工具链 (ParseSource.pl / WrapXSCheck.pl / WrapXSRun.pl)
sudo dnf install perl-ExtUtils-XSBuilder

# 覆盖率工具 (coverage)
sudo dnf install perl-Devel-Cover
```

## 使用场景

- 当 libconfig C 库升级新增 API 时，可用 `WrapXSRun.pl` 快速生成基础 XS 绑定
- 用 `WrapXSCheck.pl` 检查现有绑定是否遗漏了 C API
- 用 `coverage` 生成 HTML 覆盖率报告，查看 `cover_db/coverage.html`