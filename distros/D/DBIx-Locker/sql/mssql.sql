CREATE TABLE [locks] (
  [id] int NOT NULL IDENTITY (1, 1),
  [lockstring] varchar(128) NOT NULL,
  [created] datetime NOT NULL,
  [expires] datetime NOT NULL,
  [locked_by] text NOT NULL,
  CONSTRAINT [PK_locks] PRIMARY KEY CLUSTERED ([id]),
  CONSTRAINT [UC_locks] UNIQUE ([lockstring])
);

